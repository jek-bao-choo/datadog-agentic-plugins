package com.example.springboot3xr4j.interceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.servlet.HandlerInterceptor;

public class FaultInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(FaultInterceptor.class);
    private final double failureRate;

    public FaultInterceptor(double failureRate) {
        this.failureRate = failureRate;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if (Math.random() < failureRate) {
            log.warn("FAULT INJECTION: Simulated {}% failure on {} {}",
                    (int) (failureRate * 100), request.getMethod(), request.getRequestURI());
            response.setStatus(HttpStatus.INTERNAL_SERVER_ERROR.value());
            response.setContentType("application/json");
            response.getWriter().write(String.format(
                    "{\"error\":\"Simulated infrastructure fault\",\"service\":\"jek-otel-java-springboot3x-r4j\",\"faultRate\":\"%d%%\"}",
                    (int) (failureRate * 100)));
            return false;
        }
        return true;
    }
}
