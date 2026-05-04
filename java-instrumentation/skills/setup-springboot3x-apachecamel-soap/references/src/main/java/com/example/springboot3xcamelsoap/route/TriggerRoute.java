package com.example.springboot3xcamelsoap.route;

import com.example.springboot3xcamelsoap.client.WebMethodsClient;
import com.example.springboot3xcamelsoap.model.SubmitShipmentRequest;
import com.example.springboot3xcamelsoap.model.SubmitShipmentResponse;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.apache.camel.model.rest.RestBindingMode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Camel route — receive JSON trigger, build a SubmitShipmentRequest, call the
 * CXF JAX-WS proxy (which serializes to a SOAP envelope and POSTs to App B),
 * marshal the response back to JSON.
 *
 * Three frameworks doing what they're best at:
 *   - Spring Boot Tomcat hosts the HTTP listener
 *   - Camel REST DSL + platform-http mounts /jek-trigger on that Tomcat
 *   - CXF JaxWsProxyFactoryBean handles the SOAP wire (envelope build, send,
 *     parse response) using the SEI annotations on WebMethodsClient
 */
@Component
public class TriggerRoute extends RouteBuilder {

    private static final Logger log = LoggerFactory.getLogger(TriggerRoute.class);

    private final WebMethodsClient webMethodsClient;

    @Autowired
    public TriggerRoute(WebMethodsClient webMethodsClient) {
        this.webMethodsClient = webMethodsClient;
    }

    @Override
    public void configure() {
        restConfiguration()
                .component("platform-http")
                .bindingMode(RestBindingMode.off);   // we handle JSON ourselves to keep the route explicit

        rest("/jek-trigger")
                .post()
                .consumes("application/json")
                .produces("application/json")
                .to("direct:submit-shipment");

        from("direct:submit-shipment")
                .routeId("submit-shipment")
                .unmarshal().json(JsonLibrary.Jackson, Map.class)
                .process(exchange -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> body = exchange.getIn().getBody(Map.class);
                    String tid = String.valueOf(body.getOrDefault("tid", ""));
                    String payload = String.valueOf(body.getOrDefault("payload", "from-camel-soap-client"));

                    log.info("Calling webMethods SOAP submitShipment — TID={}", tid);

                    SubmitShipmentRequest req = new SubmitShipmentRequest();
                    req.setTID(tid);
                    req.setPayload(payload);

                    SubmitShipmentResponse resp = webMethodsClient.submitShipment(req);

                    Map<String, Object> result = new LinkedHashMap<>();
                    result.put("tid", resp.getTID());
                    result.put("status", resp.getStatus());
                    result.put("received_at", resp.getReceived_at());
                    exchange.getMessage().setBody(result);
                })
                .marshal().json(JsonLibrary.Jackson);
    }
}
