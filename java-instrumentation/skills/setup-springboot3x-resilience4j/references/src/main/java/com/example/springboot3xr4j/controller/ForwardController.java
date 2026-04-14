package com.example.springboot3xr4j.controller;

import com.example.springboot3xr4j.service.ComponentCClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
public class ForwardController {

    private static final Logger log = LoggerFactory.getLogger(ForwardController.class);
    private final ComponentCClient componentCClient;

    public ForwardController(ComponentCClient componentCClient) {
        this.componentCClient = componentCClient;
    }

    @PostMapping("/jek-forward")
    public String forward(@RequestBody Map<String, Object> payload) {
        // Generate airway_bill_id — simulates freight forwarder assigning Master AWB
        String awbId = UUID.randomUUID().toString();
        payload.put("airway_bill_id", awbId);
        payload.put("source", "component-b");

        log.info("Forwarding — transaction_id={}, airway_bill_id={}", payload.get("transaction_id"), awbId);

        // Forward to Component C with Resilience4j retry + circuit breaker
        return componentCClient.callComponentC(payload);
    }
}
