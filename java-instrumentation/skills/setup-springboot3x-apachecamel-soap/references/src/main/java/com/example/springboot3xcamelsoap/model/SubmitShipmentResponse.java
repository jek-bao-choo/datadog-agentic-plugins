package com.example.springboot3xcamelsoap.model;

import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlElement;
import jakarta.xml.bind.annotation.XmlRootElement;
import jakarta.xml.bind.annotation.XmlType;

/**
 * Mirrors App B's SubmitShipmentResponse exactly. CXF unmarshals the SOAP
 * response into this DTO when the WebMethodsClient.submitShipment proxy
 * returns.
 */
@XmlRootElement(name = "submitShipmentResponse", namespace = "http://example.com/webmethods")
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "submitShipmentResponse", namespace = "http://example.com/webmethods",
         propOrder = {"TID", "status", "received_at"})
public class SubmitShipmentResponse {

    @XmlElement(name = "TID", required = true)
    private String TID;

    @XmlElement(name = "status")
    private String status;

    @XmlElement(name = "received_at")
    private String received_at;

    public String getTID() { return TID; }
    public void setTID(String TID) { this.TID = TID; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getReceived_at() { return received_at; }
    public void setReceived_at(String received_at) { this.received_at = received_at; }
}
