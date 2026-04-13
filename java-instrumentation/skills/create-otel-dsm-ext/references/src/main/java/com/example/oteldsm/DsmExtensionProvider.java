package com.example.oteldsm;

import com.example.oteldsm.exporter.PipelineStatsExporter;
import com.example.oteldsm.processor.DsmSpanProcessor;
import com.example.oteldsm.stats.StatsAggregator;
import com.google.auto.service.AutoService;
import io.opentelemetry.sdk.autoconfigure.spi.AutoConfigurationCustomizer;
import io.opentelemetry.sdk.autoconfigure.spi.AutoConfigurationCustomizerProvider;
import io.opentelemetry.sdk.autoconfigure.spi.ConfigProperties;
import io.opentelemetry.sdk.trace.SdkTracerProviderBuilder;

/**
 * OTel Java Agent Extension entry point for Datadog Data Streams Monitoring.
 *
 * Two operating modes:
 *
 * 1. OTel Collector only (default: dsm.export.enabled=false)
 *    - SpanProcessor runs: sets pathway.hash, dsm.transaction.id on spans
 *    - Spans flow through OTel Collector → Datadog exporter → Datadog APM
 *    - DSM Traces section in Datadog works (queries dsm.transaction.id)
 *    - No DD Agent needed, no background thread, no pipeline_stats export
 *
 * 2. Full DSM export (dsm.export.enabled=true)
 *    - Everything from mode 1, PLUS:
 *    - StatsAggregator batches stats into 10-second buckets
 *    - PipelineStatsExporter sends MessagePack+gzip to DD Agent /v0.1/pipeline_stats
 *    - Requires DD Agent running on localhost:8126 (or dsm.agent.url)
 *
 * Configuration (via -D flags or env vars):
 *   - dsm.export.enabled: Enable DD Agent export (default: false)
 *   - dsm.agent.url: Datadog Agent URL (default: http://localhost:8126)
 *   - otel.service.name: used as the DSM service name
 *   - otel.resource.attributes: deployment.environment used as DSM env
 */
@AutoService(AutoConfigurationCustomizerProvider.class)
public class DsmExtensionProvider implements AutoConfigurationCustomizerProvider {

    @Override
    public void customize(AutoConfigurationCustomizer autoConfiguration) {
        autoConfiguration.addTracerProviderCustomizer(this::configureTracer);
    }

    private SdkTracerProviderBuilder configureTracer(
            SdkTracerProviderBuilder tracerProvider, ConfigProperties config) {

        boolean exportEnabled = Boolean.parseBoolean(
                config.getString("dsm.export.enabled", "false"));
        String agentUrl = config.getString("dsm.agent.url", "http://localhost:8126");
        String service = config.getString("otel.service.name", "unknown-service");
        String env = extractEnv(config);

        System.out.println("[otel-dsm] Initializing Datadog DSM extension");
        System.out.println("[otel-dsm]   Export to DD Agent: " + (exportEnabled ? "ENABLED → " + agentUrl : "DISABLED (OTel Collector only)"));
        System.out.println("[otel-dsm]   Service: " + service);
        System.out.println("[otel-dsm]   Env: " + env);

        StatsAggregator aggregator;
        if (exportEnabled) {
            PipelineStatsExporter exporter = new PipelineStatsExporter(agentUrl);
            aggregator = new StatsAggregator(exporter, env, service);
            System.out.println("[otel-dsm]   Mode: Full DSM (span attributes + pipeline_stats export)");
        } else {
            // No-op aggregator: accepts StatsPoints but doesn't export
            aggregator = new StatsAggregator(null, env, service);
            System.out.println("[otel-dsm]   Mode: Span attributes only (dsm.transaction.id → OTel Collector → Datadog)");
        }

        DsmSpanProcessor processor = new DsmSpanProcessor(aggregator);
        return tracerProvider.addSpanProcessor(processor);
    }

    private String extractEnv(ConfigProperties config) {
        String resourceAttrs = config.getString("otel.resource.attributes", "");
        for (String pair : resourceAttrs.split(",")) {
            String[] kv = pair.split("=", 2);
            if (kv.length == 2 && kv[0].trim().equals("deployment.environment")) {
                return kv[1].trim();
            }
        }
        return "none";
    }

    @Override
    public int order() {
        return 100;
    }
}
