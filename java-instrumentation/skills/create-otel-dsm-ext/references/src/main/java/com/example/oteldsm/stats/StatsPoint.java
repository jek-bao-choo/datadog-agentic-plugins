package com.example.oteldsm.stats;

import java.util.List;

/**
 * A single data point emitted by the SpanProcessor for a messaging checkpoint.
 */
public final class StatsPoint {

    private final long hash;
    private final long parentHash;
    private final List<String> edgeTags;
    private final long pathwayLatencyMillis;
    private final long edgeLatencyMillis;
    private final long timestampNanos;
    private final String transactionId;       // null if no transaction
    private final int transactionCheckpoint;  // 0 if no transaction

    public StatsPoint(long hash, long parentHash, List<String> edgeTags,
                      long pathwayLatencyMillis, long edgeLatencyMillis,
                      long timestampNanos, String transactionId, int transactionCheckpoint) {
        this.hash = hash;
        this.parentHash = parentHash;
        this.edgeTags = edgeTags;
        this.pathwayLatencyMillis = pathwayLatencyMillis;
        this.edgeLatencyMillis = edgeLatencyMillis;
        this.timestampNanos = timestampNanos;
        this.transactionId = transactionId;
        this.transactionCheckpoint = transactionCheckpoint;
    }

    public long getHash() { return hash; }
    public long getParentHash() { return parentHash; }
    public List<String> getEdgeTags() { return edgeTags; }
    public long getPathwayLatencyMillis() { return pathwayLatencyMillis; }
    public long getEdgeLatencyMillis() { return edgeLatencyMillis; }
    public long getTimestampNanos() { return timestampNanos; }
    public String getTransactionId() { return transactionId; }
    public int getTransactionCheckpoint() { return transactionCheckpoint; }
    public boolean hasTransaction() { return transactionId != null && !transactionId.isEmpty(); }
}
