package com.example.springboot3xsoap.config;

import com.example.springboot3xsoap.endpoint.WebMethodsMockEndpointImpl;
import com.example.springboot3xsoap.interceptor.FaultInterceptor;
import jakarta.xml.ws.Endpoint;
import org.apache.cxf.Bus;
import org.apache.cxf.jaxws.EndpointImpl;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CxfConfig {

    /**
     * Publishes the SEI implementation at /webmethods (relative to the CXF
     * servlet path, which is set to "/ws" in application.properties — combined:
     * /ws/webmethods, with the WSDL at /ws/webmethods?wsdl).
     */
    @Bean
    public Endpoint webMethodsEndpoint(Bus bus, WebMethodsMockEndpointImpl impl) {
        EndpointImpl endpoint = new EndpointImpl(bus, impl);
        endpoint.publish("/webmethods");
        return endpoint;
    }

    /**
     * 10% probabilistic SOAP fault. Registered on the bus's IN chain so it fires
     * for every CXF-routed request — and only for those (Spring MVC routes like
     * /actuator/health are unaffected).
     */
    @Bean
    public FaultInterceptor faultInterceptor(Bus bus) {
        FaultInterceptor interceptor = new FaultInterceptor(0.10);
        bus.getInInterceptors().add(interceptor);
        return interceptor;
    }
}
