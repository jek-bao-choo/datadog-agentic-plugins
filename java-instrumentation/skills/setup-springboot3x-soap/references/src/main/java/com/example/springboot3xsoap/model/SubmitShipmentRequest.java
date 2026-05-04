package com.example.springboot3xsoap.model;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlElement;
import jakarta.xml.bind.annotation.XmlRootElement;
import jakarta.xml.bind.annotation.XmlType;

@XmlRootElement(name = "submitShipment", namespace = "http://example.com/webmethods")
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "submitShipment", namespace = "http://example.com/webmethods",
         propOrder = {"TID", "payload"})
public class SubmitShipmentRequest {

    @XmlElement(name = "TID", required = true)
    private String TID;

    @XmlElement(name = "payload")
    private String payload;

    public String getTID() { return TID; }
    public void setTID(String TID) { this.TID = TID; }

    public String getPayload() { return payload; }
    public void setPayload(String payload) { this.payload = payload; }
}
