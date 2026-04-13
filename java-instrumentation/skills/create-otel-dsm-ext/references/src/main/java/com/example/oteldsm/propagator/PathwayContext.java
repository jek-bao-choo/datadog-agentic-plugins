package com.example.oteldsm.propagator;

/**
 * Immutable pathway context that travels across service boundaries.
 * Contains the current pathway hash, pathway start time, and edge start time.
 *
 * Reference: dd-trace-java DefaultPathwayContext.java
 */
public final class PathwayContext {

    private final long hash;
    private final long pathwayStartMillis;
    private final long edgeStartMillis;

    public PathwayContext(long hash, long pathwayStartMillis, long edgeStartMillis) {
        this.hash = hash;
        this.pathwayStartMillis = pathwayStartMillis;
        this.edgeStartMillis = edgeStartMillis;
    }

    /** Create a new root context (first checkpoint in a pathway). */
    public static PathwayContext newRoot() {
        long now = System.currentTimeMillis();
        return new PathwayContext(0L, now, now);
    }

    /** Create a child context with a new hash (after a checkpoint). */
    public PathwayContext withNewHash(long newHash) {
        return new PathwayContext(newHash, pathwayStartMillis, System.currentTimeMillis());
    }

    public long getHash() { return hash; }
    public long getPathwayStartMillis() { return pathwayStartMillis; }
    public long getEdgeStartMillis() { return edgeStartMillis; }

    /** Pathway latency = now - pathwayStart. */
    public long pathwayLatencyMillis() {
        return System.currentTimeMillis() - pathwayStartMillis;
    }

    /** Edge latency = now - edgeStart. */
    public long edgeLatencyMillis() {
        return System.currentTimeMillis() - edgeStartMillis;
    }
}
