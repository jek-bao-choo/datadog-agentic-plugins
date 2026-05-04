package com.example.springboot3xcamelsoap.client;

import com.example.springboot3xcamelsoap.model.SubmitShipmentRequest;
import com.example.springboot3xcamelsoap.model.SubmitShipmentResponse;
import jakarta.jws.WebMethod;
import jakarta.jws.WebParam;
import jakarta.jws.WebResult;
import jakarta.jws.WebService;
import jakarta.jws.soap.SOAPBinding;

/**
 * Client-side SEI for App B's webMethods mock. Mirrors the @WebService
 * annotations on App B's WebMethodsMockEndpoint exactly — namespace, name,
 * SOAPBinding style/parameter style, operation name, and parameter/result
 * names — so the SOAP envelope built by the JaxWsProxyFactoryBean matches
 * the WSDL App B publishes at /ws/webmethods?wsdl.
 *
 * IMPORTANT: when copying this skill into a new prospect's PoC, the four
 * places that touch the wire format and must agree across both apps are:
 *   1. @WebService(targetNamespace = ...) here and on App B
 *   2. @WebParam / @WebResult names + namespaces here and on App B
 *   3. @XmlRootElement + @XmlType (propOrder) on the shared DTOs
 *   4. SOAPBinding style + parameterStyle on both interfaces
 */
@WebService(targetNamespace = "http://example.com/webmethods", name = "WebMethodsMock")
@SOAPBinding(style = SOAPBinding.Style.DOCUMENT, parameterStyle = SOAPBinding.ParameterStyle.BARE)
public interface WebMethodsClient {

    @WebMethod(operationName = "submitShipment")
    @WebResult(name = "submitShipmentResponse", targetNamespace = "http://example.com/webmethods")
    SubmitShipmentResponse submitShipment(
            @WebParam(name = "submitShipment", targetNamespace = "http://example.com/webmethods")
            SubmitShipmentRequest request);
}
