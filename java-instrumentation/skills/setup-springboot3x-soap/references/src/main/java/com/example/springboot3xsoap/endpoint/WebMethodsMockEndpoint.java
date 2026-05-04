package com.example.springboot3xsoap.endpoint;

import com.example.springboot3xsoap.model.SubmitShipmentRequest;
import com.example.springboot3xsoap.model.SubmitShipmentResponse;
import jakarta.jws.WebMethod;
import jakarta.jws.WebParam;
import jakarta.jws.WebResult;
import jakarta.jws.WebService;
import jakarta.jws.soap.SOAPBinding;

@WebService(targetNamespace = "http://example.com/webmethods", name = "WebMethodsMock")
@SOAPBinding(style = SOAPBinding.Style.DOCUMENT, parameterStyle = SOAPBinding.ParameterStyle.BARE)
public interface WebMethodsMockEndpoint {

    @WebMethod(operationName = "submitShipment")
    @WebResult(name = "submitShipmentResponse", targetNamespace = "http://example.com/webmethods")
    SubmitShipmentResponse submitShipment(
            @WebParam(name = "submitShipment", targetNamespace = "http://example.com/webmethods")
            SubmitShipmentRequest request);
}
