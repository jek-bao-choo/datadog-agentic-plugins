package com.example.oteldsm.exporter;

import com.example.oteldsm.stats.StatsBucket;

import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.zip.GZIPOutputStream;

/**
 * HTTP exporter that sends MessagePack-serialized DSM stats to the Datadog Agent
 * at /v0.1/pipeline_stats.
 *
 * The Datadog Agent forwards this to the Datadog backend for DSM visualization.
 *
 * Reference: dd-trace-java DefaultDataStreamsMonitoring (export logic)
 */
public class PipelineStatsExporter {

    private final String agentUrl;
    private final HttpClient httpClient;

    /**
     * @param agentUrl Base URL of the Datadog Agent (default: http://localhost:8126)
     */
    public PipelineStatsExporter(String agentUrl) {
        this.agentUrl = agentUrl;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
    }

    /**
     * Export stats buckets to the Datadog Agent.
     */
    public void export(List<StatsBucket> buckets, String env, String service) {
        if (buckets.isEmpty()) return;

        try {
            byte[] payload = MsgPackSerializer.serialize(buckets, env, service);

            // Gzip compress — DD Agent requires Content-Encoding: gzip
            byte[] gzipped = gzip(payload);

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(agentUrl + "/v0.1/pipeline_stats"))
                    .header("Content-Type", "application/msgpack")
                    .header("Content-Encoding", "gzip")
                    .header("Datadog-Meta-Tracer-Version", "otel-dsm-ext-1.0")
                    .header("Datadog-Meta-Lang", "java")
                    .POST(HttpRequest.BodyPublishers.ofByteArray(gzipped))
                    .timeout(Duration.ofSeconds(10))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                System.out.println("[otel-dsm] Successfully exported " + buckets.size() +
                        " bucket(s) to " + agentUrl + "/v0.1/pipeline_stats (" +
                        response.statusCode() + ")");
            } else {
                System.err.println("[otel-dsm] Failed to export stats: HTTP " +
                        response.statusCode() + " — " + response.body());
            }
        } catch (Exception e) {
            System.err.println("[otel-dsm] Error exporting stats to " + agentUrl + ": " + e.getMessage());
        }
    }

    private static byte[] gzip(byte[] data) throws java.io.IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (GZIPOutputStream gzos = new GZIPOutputStream(baos)) {
            gzos.write(data);
        }
        return baos.toByteArray();
    }
}
