package com.example.springboot3xcamel.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "healthy",
                "service", "jek-otel-java-springboot3x-camel",
                "port", 8083,
                "esb", "apache-camel-mock"
        );
    }
}
