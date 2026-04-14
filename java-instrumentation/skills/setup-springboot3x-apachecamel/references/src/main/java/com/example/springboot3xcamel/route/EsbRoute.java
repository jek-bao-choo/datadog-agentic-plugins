package com.example.springboot3xcamel.route;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.model.dataformat.JsonLibrary;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * Apache Camel route that mocks the IBM webMethods ESB behavior:
 *
 * 1. Receives JSON from upstream (Component B)
 * 2. Unmarshals JSON into Map (simulates webMethods IData pipeline)
 * 3. Generates houseway_bill_id (simulates webMethods Java service node)
 * 4. 80/20 probabilistic branching (simulates webMethods BRANCH flow step)
 *    - 80% pristine pass-through
 *    - 20% mutates transaction_id and airway_bill_id
 * 5. Marshals Map to XML (simulates webMethods pub.xml:documentToXMLString)
 * 6. POSTs XML to Component D (simulates webMethods HTTP POST invoke)
 */
@Component
public class EsbRoute extends RouteBuilder {

    private static final Logger log = LoggerFactory.getLogger(EsbRoute.class);

    @Override
    public void configure() {
        // Configure REST DSL to use the platform-http component
        restConfiguration()
                .component("platform-http")
                .port(8083);

        // ESB route: JSON in → XML out → Component D
        from("rest:post:/jek-process")
                .routeId("esb-json-to-xml")

                // 1. Unmarshal JSON into Map — simulates webMethods IData pipeline
                .unmarshal().json(JsonLibrary.Jackson, Map.class)

                // 2-3. Process: generate houseway_bill_id + 80/20 branching
                .process(exchange -> {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> payload = exchange.getIn().getBody(Map.class);

                    // Generate Houseway Bill ID
                    String hwbId = UUID.randomUUID().toString();
                    payload.put("houseway_bill_id", hwbId);

                    // 80/20 Probabilistic Branching
                    if (Math.random() < 0.20) {
                        payload.put("transaction_id", "MUTATED-" + payload.get("transaction_id"));
                        payload.put("airway_bill_id", "MUTATED-" + payload.get("airway_bill_id"));
                        log.warn("80/20 BRANCH: MUTATED transaction_id and airway_bill_id — hwb_id={}", hwbId);
                    } else {
                        log.info("80/20 BRANCH: PRISTINE pass-through — hwb_id={}", hwbId);
                    }

                    payload.put("source", "component-c");
                    payload.put("timestamp", Instant.now().toString());

                    exchange.getIn().setBody(payload);
                })

                // 4. Marshal Map to XML — simulates webMethods pub.xml:documentToXMLString
                .marshal().jacksonXml()

                // 5. POST XML to Component D
                .setHeader(Exchange.HTTP_METHOD, constant("POST"))
                .setHeader(Exchange.CONTENT_TYPE, constant("application/xml"))
                .log("Forwarding XML to Component D: localhost:8084/jek-receive-xml")
                .to("http://localhost:8084/jek-receive-xml?bridgeEndpoint=true");
    }
}
