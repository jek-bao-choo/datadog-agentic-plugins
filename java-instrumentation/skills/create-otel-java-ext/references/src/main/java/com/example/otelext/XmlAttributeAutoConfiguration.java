package com.example.otelext;

import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;

/**
 * Spring Boot auto-configuration that registers the XmlAttributeExtractorFilter.
 *
 * This class is discovered automatically by Spring Boot when the extension JAR
 * is on the classpath (via -Dloader.path). No @ComponentScan needed — the
 * META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
 * file tells Spring Boot to load this class.
 */
@AutoConfiguration
public class XmlAttributeAutoConfiguration {

    @Bean
    public FilterRegistrationBean<XmlAttributeExtractorFilter> xmlAttributeExtractorFilter() {
        FilterRegistrationBean<XmlAttributeExtractorFilter> registration = new FilterRegistrationBean<>();
        registration.setFilter(new XmlAttributeExtractorFilter());
        registration.addUrlPatterns("/jek-receive-xml");
        registration.setOrder(1); // Run early
        registration.setName("xmlAttributeExtractorFilter");
        return registration;
    }
}
