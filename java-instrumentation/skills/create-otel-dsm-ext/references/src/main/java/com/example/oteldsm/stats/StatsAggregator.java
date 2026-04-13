package com.example.oteldsm.stats;

import com.example.oteldsm.exporter.PipelineStatsExporter;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * Background aggregator that collects StatsPoints into 10-second buckets
 * and flushes them to the PipelineStatsExporter when each bucket closes.
 *
 * When exporter is null (dsm.export.enabled=false), the aggregator still
 * accepts StatsPoints (so the SpanProcessor works) but doesn't start the
 * background thread or export anything. This mode is used when running
 * with OTel Collector only (no DD Agent).
 *
 * Reference: dd-trace-java DefaultDataStreamsMonitoring.java (InboxProcessor)
 */
public class StatsAggregator {

    private static final long BUCKET_DURATION_NANOS = TimeUnit.SECONDS.toNanos(10);

    private final ConcurrentLinkedQueue<StatsPoint> inbox = new ConcurrentLinkedQueue<>();
    private final PipelineStatsExporter exporter; // null when export disabled
    private final String env;
    private final String service;
    private final ScheduledExecutorService scheduler;
    private final boolean exportEnabled;

    private StatsBucket currentBucket;
    private long currentBucketStart;

    /**
     * @param exporter Pipeline stats exporter. Pass null to disable export
     *                 (span attributes still work via SpanProcessor).
     */
    public StatsAggregator(PipelineStatsExporter exporter, String env, String service) {
        this.exporter = exporter;
        this.env = env;
        this.service = service;
        this.exportEnabled = (exporter != null);

        if (exportEnabled) {
            this.currentBucketStart = alignToInterval(System.nanoTime());
            this.currentBucket = new StatsBucket(currentBucketStart, BUCKET_DURATION_NANOS);

            // Background flush every 10 seconds
            this.scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
                Thread t = new Thread(r, "dsm-stats-aggregator");
                t.setDaemon(true);
                return t;
            });
            this.scheduler.scheduleAtFixedRate(this::flush, 10, 10, TimeUnit.SECONDS);
        } else {
            // No background thread, no buckets — just accept and discard StatsPoints
            this.currentBucketStart = 0;
            this.currentBucket = null;
            this.scheduler = null;
        }
    }

    /**
     * Submit a stats point (called from SpanProcessor — non-blocking).
     * When export is disabled, the point is silently discarded.
     */
    public void submit(StatsPoint point) {
        if (exportEnabled) {
            inbox.offer(point);
        }
        // When disabled, no-op — the SpanProcessor already set span attributes
    }

    /**
     * Drain the inbox, aggregate into current bucket, and flush if bucket is full.
     */
    private void flush() {
        if (!exportEnabled) return;

        try {
            // Drain inbox
            StatsPoint point;
            while ((point = inbox.poll()) != null) {
                currentBucket.add(point);
            }

            // Check if current bucket should be flushed
            long now = System.nanoTime();
            if (now - currentBucketStart >= BUCKET_DURATION_NANOS) {
                if (!currentBucket.isEmpty()) {
                    List<StatsBucket> buckets = new ArrayList<>();
                    buckets.add(currentBucket);
                    exporter.export(buckets, env, service);
                }

                // Start new bucket
                currentBucketStart = alignToInterval(now);
                currentBucket = new StatsBucket(currentBucketStart, BUCKET_DURATION_NANOS);
            }
        } catch (Exception e) {
            System.err.println("[otel-dsm] Error flushing stats: " + e.getMessage());
        }
    }

    /**
     * Flush remaining data and shut down (called on JVM shutdown).
     */
    public void shutdown() {
        if (exportEnabled) {
            flush();
            scheduler.shutdown();
        }
    }

    private static long alignToInterval(long nanos) {
        return (nanos / BUCKET_DURATION_NANOS) * BUCKET_DURATION_NANOS;
    }
}
