package com.example.springboot3xcamel.config;

import com.example.springboot3xcamel.interceptor.FaultInterceptor;
import org.springframework.context.annotation.Configuration;
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
}
