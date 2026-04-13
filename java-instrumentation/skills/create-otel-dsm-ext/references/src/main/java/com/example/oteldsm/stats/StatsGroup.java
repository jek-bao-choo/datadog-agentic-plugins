package com.example.oteldsm.stats;

import java.util.List;

/**
 * Aggregated statistics for a single pathway (identified by hash).
 * Mirrors dd-trace-java StatsGroup.
 *
 * Simplified: uses min/max/sum/count instead of DDSketch histograms.
 * For production, replace with proper DDSketch implementation.
 */
public final class StatsGroup {

    private final long hash;
    private final long parentHash;
    private final List<String> edgeTags;

    // Simplified pathway latency stats (milliseconds)
    private long pathwayLatencyCount = 0;
    private long pathwayLatencySum = 0;
    private long pathwayLatencyMin = Long.MAX_VALUE;
    private long pathwayLatencyMax = Long.MIN_VALUE;

    // Simplified edge latency stats (milliseconds)
    private long edgeLatencyCount = 0;
    private long edgeLatencySum = 0;
    private long edgeLatencyMin = Long.MAX_VALUE;
    private long edgeLatencyMax = Long.MIN_VALUE;

    public StatsGroup(long hash, long parentHash, List<String> edgeTags) {
        this.hash = hash;
        this.parentHash = parentHash;
        this.edgeTags = edgeTags;
    }

    public void add(StatsPoint point) {
        pathwayLatencyCount++;
        pathwayLatencySum += point.getPathwayLatencyMillis();
        pathwayLatencyMin = Math.min(pathwayLatencyMin, point.getPathwayLatencyMillis());
        pathwayLatencyMax = Math.max(pathwayLatencyMax, point.getPathwayLatencyMillis());

        edgeLatencyCount++;
        edgeLatencySum += point.getEdgeLatencyMillis();
        edgeLatencyMin = Math.min(edgeLatencyMin, point.getEdgeLatencyMillis());
        edgeLatencyMax = Math.max(edgeLatencyMax, point.getEdgeLatencyMillis());
    }

    public long getHash() { return hash; }
    public long getParentHash() { return parentHash; }
    public List<String> getEdgeTags() { return edgeTags; }
    public long getPathwayLatencyCount() { return pathwayLatencyCount; }
    public long getEdgeLatencyCount() { return edgeLatencyCount; }

    /**
     * Serialize simplified latency stats as a placeholder byte array.
     * In production, this should return a DDSketch-serialized histogram.
     */
    public byte[] serializePathwayLatency() {
        return serializeSimpleHistogram(pathwayLatencyCount, pathwayLatencySum, pathwayLatencyMin, pathwayLatencyMax);
    }

    public byte[] serializeEdgeLatency() {
        return serializeSimpleHistogram(edgeLatencyCount, edgeLatencySum, edgeLatencyMin, edgeLatencyMax);
    }

    private byte[] serializeSimpleHistogram(long count, long sum, long min, long max) {
        // Placeholder: pack count/sum/min/max as 4 longs (32 bytes)
        // TODO: Replace with DDSketch serialization for production
        java.nio.ByteBuffer buf = java.nio.ByteBuffer.allocate(32);
        buf.putLong(count);
        buf.putLong(sum);
        buf.putLong(min == Long.MAX_VALUE ? 0 : min);
        buf.putLong(max == Long.MIN_VALUE ? 0 : max);
        return buf.array();
    }
}
