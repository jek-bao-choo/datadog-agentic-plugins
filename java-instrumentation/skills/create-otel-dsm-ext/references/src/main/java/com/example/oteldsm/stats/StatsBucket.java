package com.example.oteldsm.stats;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Time-windowed statistics bucket (10-second window).
 * Aggregates StatsPoints into StatsGroups keyed by pathway hash.
 *
 * Reference: dd-trace-java StatsBucket.java
 */
public final class StatsBucket {

    private final long startTimeNanos;
    private final long durationNanos;
    private final Map<Long, StatsGroup> groups = new HashMap<>();
    private final ByteArrayOutputStream transactionData = new ByteArrayOutputStream();
    private int transactionCount = 0;

    public StatsBucket(long startTimeNanos, long durationNanos) {
        this.startTimeNanos = startTimeNanos;
        this.durationNanos = durationNanos;
    }

    /**
     * Add a stats point to this bucket.
     */
    public void add(StatsPoint point) {
        StatsGroup group = groups.computeIfAbsent(point.getHash(),
                h -> new StatsGroup(point.getHash(), point.getParentHash(), point.getEdgeTags()));
        group.add(point);

        // Pack transaction if present
        if (point.hasTransaction() && transactionCount < 1024) {
            packTransaction(point);
            transactionCount++;
        }
    }

    /**
     * Pack a transaction into the TransactionContainer binary format:
     * [checkpointId: 1 byte] [timestamp: 8 bytes] [idLength: 1 byte] [transactionId: N bytes]
     */
    private void packTransaction(StatsPoint point) {
        try {
            byte[] idBytes = point.getTransactionId().getBytes(StandardCharsets.UTF_8);
            transactionData.write(point.getTransactionCheckpoint() & 0xFF);
            ByteBuffer ts = ByteBuffer.allocate(8);
            ts.putLong(point.getTimestampNanos());
            transactionData.write(ts.array());
            transactionData.write(idBytes.length & 0xFF);
            transactionData.write(idBytes);
        } catch (Exception e) {
            // Silently ignore packing errors
        }
    }

    public long getStartTimeNanos() { return startTimeNanos; }
    public long getDurationNanos() { return durationNanos; }
    public Map<Long, StatsGroup> getGroups() { return groups; }
    public boolean isEmpty() { return groups.isEmpty(); }
    public byte[] getTransactionBytes() { return transactionData.toByteArray(); }
    public boolean hasTransactions() { return transactionCount > 0; }
}
