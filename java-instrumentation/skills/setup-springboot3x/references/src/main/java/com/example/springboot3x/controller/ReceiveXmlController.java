package com.example.springboot3x.controller;

import com.example.springboot3x.model.Shipment;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@RestController
public class ReceiveXmlController {

    private static final Logger log = LoggerFactory.getLogger(ReceiveXmlController.class);

    @PostMapping(value = "/jek-receive-xml", consumes = MediaType.APPLICATION_XML_VALUE, produces = MediaType.APPLICATION_XML_VALUE)
    public String receiveXml(@RequestBody Shipment shipment) {
        log.info("Received shipment — transaction_id={}, airway_bill_id={}, houseway_bill_id={}",
                shipment.getTransaction_id(),
                shipment.getAirway_bill_id(),
                shipment.getHouseway_bill_id());

        return String.format("""
                <response>
                  <status>received</status>
                  <houseway_bill_id>%s</houseway_bill_id>
                  <received_at>%s</received_at>
                </response>""",
                shipment.getHouseway_bill_id(),
                Instant.now().toString());
    }
}
