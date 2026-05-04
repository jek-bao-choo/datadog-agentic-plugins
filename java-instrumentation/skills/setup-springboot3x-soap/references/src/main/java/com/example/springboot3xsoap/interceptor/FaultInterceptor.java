package com.example.springboot3xsoap.interceptor;

import org.apache.cxf.interceptor.Fault;
import org.apache.cxf.message.Message;
import org.apache.cxf.phase.AbstractPhaseInterceptor;
import org.apache.cxf.phase.Phase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Probabilistic SOAP fault injector for the CXF inbound chain.
 *
 * Sits in PRE_INVOKE so the throw happens before the SEI runs — CXF turns the
 * Fault into a SOAP fault envelope automatically. This interceptor never sees
 * /actuator/health because that path is served by Spring MVC, not the CXF servlet.
 */
public class FaultInterceptor extends AbstractPhaseInterceptor<Message> {

    private static final Logger log = LoggerFactory.getLogger(FaultInterceptor.class);
    private final double failureRate;

    public FaultInterceptor(double failureRate) {
        super(Phase.PRE_INVOKE);
        this.failureRate = failureRate;
    }

    @Override
    public void handleMessage(Message message) throws Fault {
        if (Math.random() < failureRate) {
            String operation = String.valueOf(message.get(Message.WSDL_OPERATION));
            log.warn("FAULT INJECTION: Simulated {}% failure on {}",
                    (int) (failureRate * 100), operation);
            throw new Fault(new RuntimeException(
                    "Simulated infrastructure fault on jek-otel-java-springboot3x-soap"));
        }
    }
}
