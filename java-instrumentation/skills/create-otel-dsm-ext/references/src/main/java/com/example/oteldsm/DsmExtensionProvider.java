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
 * Registers:
 *   - DsmSpanProcessor: intercepts messaging spans, computes pathway hashes,
 *     emits stats to the aggregator
 *   - StatsAggregator: background thread that batches stats into 10-second buckets
 *   - PipelineStatsExporter: sends MessagePack payloads to DD Agent /v0.1/pipeline_stats
 *
 * The DatadogPathwayPropagator is registered separately via ConfigurablePropagatorProvider.
 *
 * Load via: -Dotel.javaagent.extensions=/path/to/otel-dsm-extension-1.0.jar
 *
 * Configuration (via -D flags or env vars):
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

        String agentUrl = config.getString("dsm.agent.url", "http://localhost:8126");
        String service = config.getString("otel.service.name", "unknown-service");
        String env = extractEnv(config);

        System.out.println("[otel-dsm] Initializing Datadog DSM extension");
        System.out.println("[otel-dsm]   Agent URL: " + agentUrl);
        System.out.println("[otel-dsm]   Service: " + service);
        System.out.println("[otel-dsm]   Env: " + env);

        PipelineStatsExporter exporter = new PipelineStatsExporter(agentUrl);
        StatsAggregator aggregator = new StatsAggregator(exporter, env, service);
        DsmSpanProcessor processor = new DsmSpanProcessor(aggregator);

        return tracerProvider.addSpanProcessor(processor);
    }

    private String extractEnv(ConfigProperties config) {
        // Try to extract env from otel.resource.attributes
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
        return 100; // Run after default providers
    }
}
