package com.example.springboot3xcamelsoap.model;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlElement;
import jakarta.xml.bind.annotation.XmlRootElement;
import jakarta.xml.bind.annotation.XmlType;

/**
 * Mirrors App B's SubmitShipmentRequest exactly — same element names, same
 * namespace, same propOrder. The CXF JAX-WS proxy uses these annotations to
 * build the outgoing SOAP envelope, so any drift here breaks the wire.
 */
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
