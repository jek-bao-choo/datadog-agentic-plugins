package com.example.springboot3xcamelsoap.client;

import org.apache.cxf.jaxws.JaxWsProxyFactoryBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CxfClientConfig {

    /**
     * Builds a JAX-WS proxy that speaks SOAP to App B's webMethods endpoint.
     * Endpoint URL is configurable via webmethods.endpoint (default to the
     * loopback IP — `127.0.0.1` not `localhost` because the OTel Java Agent's
     * HTTP client interception can hit IPv6 dual-stack resolution issues with
     * `localhost`).
     */
    @Bean
    public WebMethodsClient webMethodsClient(
            @Value("${webmethods.endpoint:http://127.0.0.1:8084/ws/webmethods}") String endpoint) {
        JaxWsProxyFactoryBean factory = new JaxWsProxyFactoryBean();
        factory.setServiceClass(WebMethodsClient.class);
        factory.setAddress(endpoint);
        return (WebMethodsClient) factory.create();
    }
}
