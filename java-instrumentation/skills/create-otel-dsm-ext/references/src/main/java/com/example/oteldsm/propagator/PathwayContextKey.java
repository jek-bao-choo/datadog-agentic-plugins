package com.example.oteldsm.propagator;

import io.opentelemetry.context.ContextKey;

/**
 * OTel Context key for storing the Datadog pathway context.
 */
public final class PathwayContextKey {

    public static final ContextKey<PathwayContext> KEY =
            ContextKey.named("datadog-pathway-context");

    private PathwayContextKey() {}
}
