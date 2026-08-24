package com.example.otelextsoap;

import org.apache.cxf.Bus;
import org.apache.cxf.BusFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Bean;

/**
 * Spring Boot auto-configuration that registers the SoapTidOutInterceptor on
 * CXF's default Bus.
 *
 * Discovery: Spring Boot reads
 *   META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
 * to find this class, no @ComponentScan or app code change needed.
 *
 * Bus choice: BusFactory.getDefaultBus() returns the JVM-wide default Bus
 * (a singleton, lazily created). The consuming app's
 * `JaxWsProxyFactoryBean.create()` also uses the default Bus (when no
 * explicit Bus is set on the factory). Result: the interceptor is registered
 * on the same Bus the SOAP client uses — confirmed live in the demo
 * PoC validation.
 *
 * Bean order: even if Spring creates this @Bean AFTER the consuming app's
 * `@Bean WebMethodsClient`, the interceptor still fires on every subsequent
 * SOAP call because the Bus's interceptor list is consulted at message-send
 * time, not at proxy-creation time.
 */
@AutoConfiguration
public class SoapTidAutoConfiguration {

    private static final Logger log = LoggerFactory.getLogger(SoapTidAutoConfiguration.class);

    @Bean
    public SoapTidOutInterceptor soapTidOutInterceptor() {
        SoapTidOutInterceptor interceptor = new SoapTidOutInterceptor();
        Bus bus = BusFactory.getDefaultBus();
        bus.getOutInterceptors().add(interceptor);
        log.info("OTel SOAP extension — registered SoapTidOutInterceptor on default Bus");
        return interceptor;
    }
}
