package com.example.springboot3x.config;

import com.example.springboot3x.interceptor.FaultInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 10% fault injection on all endpoints except /health
        registry.addInterceptor(new FaultInterceptor(0.10))
                .excludePathPatterns("/health", "/actuator/**");
    }
}
