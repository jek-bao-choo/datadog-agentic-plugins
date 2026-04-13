package com.example.oteldsm.propagator;

import com.example.oteldsm.hash.VarIntCodec;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.propagation.TextMapGetter;
import io.opentelemetry.context.propagation.TextMapPropagator;
import io.opentelemetry.context.propagation.TextMapSetter;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Base64;
import java.util.Collection;
import java.util.Collections;

/**
 * TextMapPropagator that handles Datadog's dd-pathway-ctx-base64 header.
 *
 * Byte layout:
 *   [hash: 8 bytes LE] [pathwayStartMillis: signed VarInt] [edgeStartMillis: signed VarInt]
 *   → Base64 encoded
 *
 * Reference: dd-trace-java DataStreamsPropagator.java, DefaultPathwayContext.java
 */
public class DatadogPathwayPropagator implements TextMapPropagator {

    public static final String HEADER_NAME = "dd-pathway-ctx-base64";

    @Override
    public Collection<String> fields() {
        return Collections.singletonList(HEADER_NAME);
    }

    @Override
    public <C> void inject(Context context, C carrier, TextMapSetter<C> setter) {
        PathwayContext pathwayCtx = context.get(PathwayContextKey.KEY);
        if (pathwayCtx == null || pathwayCtx.getHash() == 0L) {
            return;
        }

        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream(32);

            // Write hash as 8 bytes little-endian
            byte[] hashBytes = new byte[8];
            ByteBuffer.wrap(hashBytes).order(ByteOrder.LITTLE_ENDIAN).putLong(pathwayCtx.getHash());
            out.write(hashBytes);

            // Write pathwayStartMillis as signed VarInt
            VarIntCodec.encodeSignedVarLong(out, pathwayCtx.getPathwayStartMillis());

            // Write edgeStartMillis as signed VarInt
            VarIntCodec.encodeSignedVarLong(out, pathwayCtx.getEdgeStartMillis());

            String base64 = Base64.getEncoder().encodeToString(out.toByteArray());
            setter.set(carrier, HEADER_NAME, base64);
        } catch (Exception e) {
            // Silently ignore encoding errors to avoid disrupting application
        }
    }

    @Override
    public <C> Context extract(Context context, C carrier, TextMapGetter<C> getter) {
        String headerValue = getter.get(carrier, HEADER_NAME);
        if (headerValue == null || headerValue.isEmpty()) {
            return context;
        }

        try {
            byte[] decoded = Base64.getDecoder().decode(headerValue);
            ByteArrayInputStream in = new ByteArrayInputStream(decoded);

            // Read hash: 8 bytes little-endian
            byte[] hashBytes = new byte[8];
            if (in.read(hashBytes) != 8) {
                return context;
            }
            long hash = ByteBuffer.wrap(hashBytes).order(ByteOrder.LITTLE_ENDIAN).getLong();

            // Read pathwayStartMillis: signed VarInt
            long pathwayStartMillis = VarIntCodec.decodeSignedVarLong(in);

            // Read edgeStartMillis: signed VarInt
            long edgeStartMillis = VarIntCodec.decodeSignedVarLong(in);

            PathwayContext pathwayCtx = new PathwayContext(hash, pathwayStartMillis, edgeStartMillis);
            return context.with(PathwayContextKey.KEY, pathwayCtx);
        } catch (Exception e) {
            // Silently ignore decoding errors
            return context;
        }
    }
}
