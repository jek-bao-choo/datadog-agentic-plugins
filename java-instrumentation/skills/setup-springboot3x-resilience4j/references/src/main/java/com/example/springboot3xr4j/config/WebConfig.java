package com.example.springboot3xr4j.config;

import com.example.springboot3xr4j.interceptor.FaultInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 20% fault injection on all endpoints except /health
        registry.addInterceptor(new FaultInterceptor(0.20))
                .excludePathPatterns("/health", "/actuator/**");
    }

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
