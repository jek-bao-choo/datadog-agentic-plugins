package com.example.oteldsm.hash;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;

/**
 * VarInt / ZigZag encoding and decoding for Datadog DSM pathway context.
 *
 * ZigZag encoding maps signed integers to unsigned integers so that
 * numbers with small absolute values have small VarInt encodings.
 *
 * Reference: dd-trace-java VarEncodingHelper.java
 */
public final class VarIntCodec {

    private VarIntCodec() {}

    /**
     * Encode a signed long using ZigZag + VarInt encoding.
     */
    public static void encodeSignedVarLong(ByteArrayOutputStream out, long value) {
        // ZigZag encode: (value << 1) ^ (value >> 63)
        long zigzag = (value << 1) ^ (value >> 63);
        encodeUnsignedVarLong(out, zigzag);
    }

    /**
     * Encode an unsigned long using VarInt encoding.
     */
    public static void encodeUnsignedVarLong(ByteArrayOutputStream out, long value) {
        while ((value & ~0x7FL) != 0) {
            out.write((int) ((value & 0x7F) | 0x80));
            value >>>= 7;
        }
        out.write((int) (value & 0x7F));
    }

    /**
     * Decode a signed long from ZigZag + VarInt encoding.
     */
    public static long decodeSignedVarLong(ByteArrayInputStream in) {
        long zigzag = decodeUnsignedVarLong(in);
        // ZigZag decode: (zigzag >>> 1) ^ -(zigzag & 1)
        return (zigzag >>> 1) ^ -(zigzag & 1);
    }

    /**
     * Decode an unsigned long from VarInt encoding.
     */
    public static long decodeUnsignedVarLong(ByteArrayInputStream in) {
        long result = 0;
        int shift = 0;
        int b;
        do {
            b = in.read();
            if (b == -1) throw new IllegalStateException("Unexpected end of VarInt");
            result |= (long) (b & 0x7F) << shift;
            shift += 7;
        } while ((b & 0x80) != 0);
        return result;
    }
}
