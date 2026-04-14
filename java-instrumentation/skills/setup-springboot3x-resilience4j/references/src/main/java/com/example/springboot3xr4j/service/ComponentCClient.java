package com.example.springboot3xr4j.service;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

/**
 * Client for calling Component C with Resilience4j retry + circuit breaker.
 *
 * When Component C returns 500 (20% fault injection), the retry mechanism
 * retries up to 3 times with exponential backoff. If all retries fail or
 * the circuit breaker opens, the fallback returns a cached response.
 */
@Service
public class ComponentCClient {

    private static final Logger log = LoggerFactory.getLogger(ComponentCClient.class);
    private final RestTemplate restTemplate;

    public ComponentCClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @CircuitBreaker(name = "jek-cb-to-c", fallbackMethod = "fallbackCall")
    @Retry(name = "jek-retry-to-c")
    public String callComponentC(Map<String, Object> payload) {
        log.info("Calling Component C at localhost:8083/jek-process");
        return restTemplate.postForObject(
                "http://localhost:8083/jek-process", payload, String.class);
    }

    public String fallbackCall(Map<String, Object> payload, Throwable t) {
        log.warn("Fallback triggered for Component C: {}", t.getMessage());
        return "{\"status\":\"fallback\",\"message\":\"Component C unavailable\",\"airway_bill_id\":\"" +
                payload.get("airway_bill_id") + "\"}";
    }
}
