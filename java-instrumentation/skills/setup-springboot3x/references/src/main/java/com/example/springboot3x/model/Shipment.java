package com.example.springboot3x.model;

import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;

@JacksonXmlRootElement(localName = "shipment")
public class Shipment {
    private String transaction_id;
    private String airway_bill_id;
    private String houseway_bill_id;
    private String timestamp;
    private String source;

    public String getTransaction_id() { return transaction_id; }
    public void setTransaction_id(String transaction_id) { this.transaction_id = transaction_id; }

    public String getAirway_bill_id() { return airway_bill_id; }
    public void setAirway_bill_id(String airway_bill_id) { this.airway_bill_id = airway_bill_id; }

    public String getHouseway_bill_id() { return houseway_bill_id; }
    public void setHouseway_bill_id(String houseway_bill_id) { this.houseway_bill_id = houseway_bill_id; }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
}
