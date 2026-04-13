package com.example.oteldsm.exporter;

import com.example.oteldsm.stats.StatsBucket;
import com.example.oteldsm.stats.StatsGroup;
import org.msgpack.core.MessageBufferPacker;
import org.msgpack.core.MessagePack;
import org.msgpack.value.impl.ImmutableBigIntegerValueImpl;
import java.math.BigInteger;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Serializes DSM stats into Datadog's expected MessagePack format for /v0.1/pipeline_stats.
 *
 * Schema:
 * {
 *   "Env": string,
 *   "Service": string,
 *   "Lang": "java",
 *   "TracerVersion": "otel-dsm-ext-1.0",
 *   "Version": "",
 *   "Stats": [
 *     {
 *       "Start": long, "Duration": long,
 *       "Stats": [{ "Hash": long, "ParentHash": long, "EdgeTags": [...],
 *                    "PathwayLatency": binary, "EdgeLatency": binary }],
 *       "Transactions": binary (optional)
 *     }
 *   ]
 * }
 *
 * Reference: dd-trace-java MsgPackDatastreamsPayloadWriter.java
 */
public final class MsgPackSerializer {

    private MsgPackSerializer() {}

    /**
     * Serialize stats buckets into a MessagePack byte array.
     */
    public static byte[] serialize(List<StatsBucket> buckets, String env, String service) throws IOException {
        try (MessageBufferPacker packer = MessagePack.newDefaultBufferPacker()) {
            // Top-level map: 7 fields
            packer.packMapHeader(7);

            packer.packString("Env");
            packer.packString(env != null ? env : "");

            packer.packString("Service");
            packer.packString(service != null ? service : "");

            packer.packString("Lang");
            packer.packString("java");

            packer.packString("TracerVersion");
            packer.packString("otel-dsm-ext-1.0");

            packer.packString("Version");
            packer.packString("");

            packer.packString("ProductMask");
            packer.packLong(2L); // DSM = 2

            // Stats array
            packer.packString("Stats");
            packer.packArrayHeader(buckets.size());

            for (StatsBucket bucket : buckets) {
                serializeBucket(packer, bucket);
            }

            return packer.toByteArray();
        }
    }

    private static void serializeBucket(MessageBufferPacker packer, StatsBucket bucket) throws IOException {
        int fields = 3 + (bucket.hasTransactions() ? 1 : 0);
        packer.packMapHeader(fields);

        packer.packString("Start");
        packer.packLong(bucket.getStartTimeNanos());

        packer.packString("Duration");
        packer.packLong(bucket.getDurationNanos());

        // Stats groups
        Map<Long, StatsGroup> groups = bucket.getGroups();
        packer.packString("Stats");
        packer.packArrayHeader(groups.size());

        for (StatsGroup group : groups.values()) {
            serializeStatsGroup(packer, group);
        }

        // Transactions (optional)
        if (bucket.hasTransactions()) {
            packer.packString("Transactions");
            byte[] txBytes = bucket.getTransactionBytes();
            packer.packBinaryHeader(txBytes.length);
            packer.writePayload(txBytes);
        }
    }

    /**
     * Pack a long as unsigned 64-bit integer in MessagePack.
     * FNV-1a hashes are 64-bit values that may have the high bit set,
     * which Java interprets as negative. The DD Agent expects unsigned.
     */
    private static void packUnsignedLong(MessageBufferPacker packer, long value) throws IOException {
        if (value >= 0) {
            packer.packLong(value);
        } else {
            // Convert to unsigned BigInteger representation
            BigInteger unsigned = BigInteger.valueOf(value & 0x7FFFFFFFFFFFFFFFL)
                    .add(BigInteger.valueOf(Long.MIN_VALUE).negate().add(BigInteger.valueOf(value & 0x7FFFFFFFFFFFFFFFL)));
            // Actually, simpler: treat as unsigned by using the raw 8-byte format
            // MessagePack uint64 format: 0xcf followed by 8 bytes big-endian
            packer.addPayload(new byte[]{
                    (byte) 0xcf,
                    (byte) (value >>> 56), (byte) (value >>> 48),
                    (byte) (value >>> 40), (byte) (value >>> 32),
                    (byte) (value >>> 24), (byte) (value >>> 16),
                    (byte) (value >>> 8), (byte) value
            });
        }
    }

    private static void serializeStatsGroup(MessageBufferPacker packer, StatsGroup group) throws IOException {
        packer.packMapHeader(5);

        packer.packString("Hash");
        packUnsignedLong(packer, group.getHash());

        packer.packString("ParentHash");
        packUnsignedLong(packer, group.getParentHash());

        // Edge tags
        packer.packString("EdgeTags");
        List<String> tags = group.getEdgeTags();
        packer.packArrayHeader(tags.size());
        for (String tag : tags) {
            packer.packString(tag);
        }

        // PathwayLatency (binary — simplified histogram)
        packer.packString("PathwayLatency");
        byte[] pathwayLatency = group.serializePathwayLatency();
        packer.packBinaryHeader(pathwayLatency.length);
        packer.writePayload(pathwayLatency);

        // EdgeLatency (binary — simplified histogram)
        packer.packString("EdgeLatency");
        byte[] edgeLatency = group.serializeEdgeLatency();
        packer.packBinaryHeader(edgeLatency.length);
        packer.writePayload(edgeLatency);
    }
}
