package com.example.oteldsm.processor;

import com.example.oteldsm.hash.FnvHash;
import com.example.oteldsm.propagator.PathwayContext;
import com.example.oteldsm.propagator.PathwayContextKey;
import com.example.oteldsm.stats.StatsAggregator;
import com.example.oteldsm.stats.StatsPoint;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.context.Context;
import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.trace.ReadWriteSpan;
import io.opentelemetry.sdk.trace.ReadableSpan;
import io.opentelemetry.sdk.trace.SpanProcessor;

import java.util.ArrayList;
import java.util.List;

/**
 * SpanProcessor that intercepts messaging spans to compute Datadog DSM pathway hashes
 * and emit stats points for aggregation.
 *
 * On span start:
 *   - Extracts parent PathwayContext from OTel Context
 *   - Computes new pathway hash (FNV-1a of nodeHash + parentHash)
 *   - Sets pathway.hash attribute on the span (CRITICAL for Datadog correlation)
 *
 * On span end:
 *   - Emits a StatsPoint to the aggregator with latency measurements
 *
 * Reference: dd-trace-java DataStreamsMonitoring (checkpoint logic)
 */
public class DsmSpanProcessor implements SpanProcessor {

    // OTel semantic conventions
    private static final AttributeKey<String> MESSAGING_DESTINATION =
            AttributeKey.stringKey("messaging.destination.name");
    private static final AttributeKey<String> MESSAGING_SYSTEM =
            AttributeKey.stringKey("messaging.system");
    private static final AttributeKey<String> HTTP_ROUTE =
            AttributeKey.stringKey("http.route");

    // TESTING MODE: also process SERVER spans (HTTP) to test the pipeline
    // without a real messaging system. Set to false for production.
    private static final boolean TESTING_MODE = true;

    // Custom attributes for Datadog DSM correlation
    private static final AttributeKey<Long> PATHWAY_HASH =
            AttributeKey.longKey("pathway.hash");
    private static final AttributeKey<String> DSM_TRANSACTION_ID =
            AttributeKey.stringKey("dsm.transaction.id");
    private static final AttributeKey<Long> DSM_TRANSACTION_CHECKPOINT =
            AttributeKey.longKey("dsm.transaction.checkpoint");

    // User-defined transaction ID (set by XML extractor extension as a span attribute)
    private static final AttributeKey<String> TRANSACTION_ID =
            AttributeKey.stringKey("transaction_id");

    private final StatsAggregator aggregator;
    private int checkpointCounter = 0;

    public DsmSpanProcessor(StatsAggregator aggregator) {
        this.aggregator = aggregator;
    }

    @Override
    public void onStart(Context parentContext, ReadWriteSpan span) {
        // Only process messaging spans (PRODUCER or CONSUMER)
        if (!isMessagingSpan(span)) {
            return;
        }

        // Get parent pathway context (extracted by the propagator)
        PathwayContext parentPathway = parentContext.get(PathwayContextKey.KEY);
        if (parentPathway == null) {
            parentPathway = PathwayContext.newRoot();
        }

        // Build checkpoint string for hashing
        String destination = span.getAttribute(MESSAGING_DESTINATION);
        String system = span.getAttribute(MESSAGING_SYSTEM);
        String direction = span.getKind() == SpanKind.PRODUCER ? "out" : "in";

        // TESTING MODE: for SERVER spans, use HTTP route as destination
        if (destination == null && TESTING_MODE) {
            destination = span.getAttribute(HTTP_ROUTE);
            if (destination == null) destination = span.getName();
            system = "http";
            direction = "in";
        }

        String checkpoint = buildCheckpoint(system, direction, destination);
        long nodeHash = FnvHash.nodeHash(checkpoint);
        long newHash = FnvHash.pathwayHash(nodeHash, parentPathway.getHash());

        // CRITICAL: Set pathway.hash on span for Datadog correlation
        span.setAttribute(PATHWAY_HASH, newHash);

        // If the span has a transaction.id, set DSM transaction attributes
        String transactionId = span.getAttribute(TRANSACTION_ID);
        if (transactionId != null && !transactionId.isEmpty()) {
            span.setAttribute(DSM_TRANSACTION_ID, transactionId);
            span.setAttribute(DSM_TRANSACTION_CHECKPOINT, (long) checkpointCounter);
        }

        // Update the pathway context for downstream propagation
        PathwayContext newPathway = parentPathway.withNewHash(newHash);
        // Store in Context for the propagator to inject into outgoing messages
        // Note: The propagator reads from Context via PathwayContextKey
    }

    @Override
    public void onEnd(ReadableSpan span) {
        if (!isMessagingSpan(span)) {
            return;
        }

        Long hash = span.getAttribute(PATHWAY_HASH);
        if (hash == null) {
            return;
        }

        // Build edge tags
        String destination = span.getAttribute(MESSAGING_DESTINATION);
        String system = span.getAttribute(MESSAGING_SYSTEM);
        String direction = span.getKind() == SpanKind.PRODUCER ? "out" : "in";

        // TESTING MODE: for SERVER spans, use HTTP route
        if (destination == null && TESTING_MODE) {
            destination = span.getAttribute(HTTP_ROUTE);
            if (destination == null) destination = span.getName();
            system = "http";
            direction = "in";
        }

        List<String> edgeTags = buildEdgeTags(system, direction, destination);

        // Get transaction info
        String transactionId = span.getAttribute(TRANSACTION_ID);
        Long transactionCheckpoint = span.getAttribute(DSM_TRANSACTION_CHECKPOINT);

        // Emit stats point
        StatsPoint point = new StatsPoint(
                hash,
                0L, // parentHash — would need to be passed from onStart
                edgeTags,
                0L, // pathwayLatencyMillis — simplified, would come from PathwayContext
                0L, // edgeLatencyMillis — simplified
                System.nanoTime(),
                transactionId,
                transactionCheckpoint != null ? transactionCheckpoint.intValue() : 0
        );

        aggregator.submit(point);
        checkpointCounter++;
    }

    @Override
    public boolean isStartRequired() { return true; }

    @Override
    public boolean isEndRequired() { return true; }

    @Override
    public CompletableResultCode shutdown() {
        aggregator.shutdown();
        return CompletableResultCode.ofSuccess();
    }

    @Override
    public CompletableResultCode forceFlush() {
        return CompletableResultCode.ofSuccess();
    }

    private boolean isMessagingSpan(ReadableSpan span) {
        if (span.getKind() == SpanKind.PRODUCER || span.getKind() == SpanKind.CONSUMER) {
            return true;
        }
        // TESTING MODE: also accept SERVER spans to test with HTTP endpoints
        return TESTING_MODE && span.getKind() == SpanKind.SERVER;
    }

    private boolean isMessagingSpan(ReadWriteSpan span) {
        if (span.getKind() == SpanKind.PRODUCER || span.getKind() == SpanKind.CONSUMER) {
            return true;
        }
        return TESTING_MODE && span.getKind() == SpanKind.SERVER;
    }

    private String buildCheckpoint(String system, String direction, String destination) {
        StringBuilder sb = new StringBuilder();
        if (system != null) sb.append("type:").append(system).append(",");
        sb.append("direction:").append(direction);
        if (destination != null) sb.append(",topic:").append(destination);
        return sb.toString();
    }

    private List<String> buildEdgeTags(String system, String direction, String destination) {
        List<String> tags = new ArrayList<>();
        if (system != null) tags.add("type:" + system);
        tags.add("direction:" + direction);
        if (destination != null) tags.add("topic:" + destination);
        return tags;
    }
}
