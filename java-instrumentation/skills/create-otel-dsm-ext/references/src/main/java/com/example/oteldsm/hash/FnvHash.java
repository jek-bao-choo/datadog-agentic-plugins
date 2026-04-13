package com.example.oteldsm.hash;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;

/**
 * FNV-1a 64-bit hash implementation.
 * Used by Datadog DSM to compute pathway hashes from checkpoint strings.
 *
 * Reference: dd-trace-java FNV64Hash.java
 */
public final class FnvHash {

    private static final long FNV_OFFSET_BASIS = 0xcbf29ce484222325L;
    private static final long FNV_PRIME = 0x100000001b3L;

    private FnvHash() {}

    /**
     * Compute FNV-1a 64-bit hash of a byte array.
     */
    public static long hash(byte[] data) {
        return hash(data, 0, data.length);
    }

    /**
     * Compute FNV-1a 64-bit hash of a byte array range.
     */
    public static long hash(byte[] data, int offset, int length) {
        long hash = FNV_OFFSET_BASIS;
        for (int i = offset; i < offset + length; i++) {
            hash ^= (data[i] & 0xFF);
            hash *= FNV_PRIME;
        }
        return hash;
    }

    /**
     * Compute the node hash from a checkpoint string.
     * Example: "type:kafka,direction:out,topic:orders"
     */
    public static long nodeHash(String checkpoint) {
        return hash(checkpoint.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Compute the pathway hash by combining nodeHash and parentHash.
     * This mirrors dd-trace-java's generatePathwayHash:
     *   writeLongLE(nodeHash) + writeLongLE(parentHash) → FNV-1a of 16 bytes
     */
    public static long pathwayHash(long nodeHash, long parentHash) {
        byte[] input = new byte[16];
        ByteBuffer buf = ByteBuffer.wrap(input).order(ByteOrder.LITTLE_ENDIAN);
        buf.putLong(nodeHash);
        buf.putLong(parentHash);
        return hash(input);
    }
}
