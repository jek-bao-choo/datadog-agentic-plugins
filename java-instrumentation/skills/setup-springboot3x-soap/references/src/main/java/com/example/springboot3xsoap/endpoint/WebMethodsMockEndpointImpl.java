package com.example.springboot3xsoap.endpoint;

import com.example.springboot3xsoap.model.SubmitShipmentRequest;
import com.example.springboot3xsoap.model.SubmitShipmentResponse;
import jakarta.jws.WebService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
@WebService(
        targetNamespace = "http://example.com/webmethods",
        endpointInterface = "com.example.springboot3xsoap.endpoint.WebMethodsMockEndpoint",
        serviceName = "WebMethodsMockService",
        portName = "WebMethodsMockPort")
public class WebMethodsMockEndpointImpl implements WebMethodsMockEndpoint {

    private static final Logger log = LoggerFactory.getLogger(WebMethodsMockEndpointImpl.class);

    @Override
    public SubmitShipmentResponse submitShipment(SubmitShipmentRequest request) {
        String tid = request != null ? request.getTID() : null;
        String payload = request != null ? request.getPayload() : null;

        log.info("Received SOAP submitShipment — TID={}, payload={}", tid, payload);

        SubmitShipmentResponse response = new SubmitShipmentResponse();
        response.setTID(tid);
        response.setStatus("received");
        response.setReceived_at(Instant.now().toString());
        return response;
    }
}
