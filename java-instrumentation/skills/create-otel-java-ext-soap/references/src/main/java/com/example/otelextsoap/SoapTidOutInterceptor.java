package com.example.otelextsoap;

import io.opentelemetry.api.trace.Span;
import org.apache.cxf.interceptor.Fault;
import org.apache.cxf.io.CacheAndWriteOutputStream;
import org.apache.cxf.io.CachedOutputStream;
import org.apache.cxf.io.CachedOutputStreamCallback;
import org.apache.cxf.message.Message;
import org.apache.cxf.phase.AbstractPhaseInterceptor;
import org.apache.cxf.phase.Phase;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.OutputStream;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * CXF outbound interceptor — captures the outgoing SOAP envelope, regex-extracts
 * &lt;TID&gt; and attaches it as a `tid` span attribute on the active OTel span.
 *
 * Phase choice: PRE_STREAM. We want to wrap the OutputStream BEFORE CXF's StAX
 * writer starts emitting bytes, so the cache callback sees the full envelope
 * once the body has been written.
 *
 * The active span comes from the OTel Java Agent's HTTP client instrumentation
 * (which wraps CXF's HttpClientHTTPConduit). Without the agent, Span.current()
 * returns the no-op span and setAttribute is silently dropped — no harm done.
 */
public class SoapTidOutInterceptor extends AbstractPhaseInterceptor<Message> {

    private static final Logger log = LoggerFactory.getLogger(SoapTidOutInterceptor.class);

    /**
     * Matches &lt;TID&gt;...&lt;/TID&gt; tolerating an optional XML namespace
     * prefix (e.g., &lt;ns2:TID&gt;...&lt;/ns2:TID&gt;). For prospect adaptation,
     * change this regex — see SKILL.md / README.md.
     */
    private static final Pattern TID_PATTERN =
            Pattern.compile("<(?:\\w+:)?TID>([^<]+)</(?:\\w+:)?TID>");

    public SoapTidOutInterceptor() {
        super(Phase.PRE_STREAM);
    }

    @Override
    public void handleMessage(Message message) throws Fault {
        OutputStream os = message.getContent(OutputStream.class);
        if (os == null) {
            return;
        }
        CacheAndWriteOutputStream cwos = new CacheAndWriteOutputStream(os);
        message.setContent(OutputStream.class, cwos);
        cwos.registerCallback(new TidCaptureCallback());
    }

    /**
     * Fires synchronously after the envelope has been fully written. Reads the
     * cached bytes, regex-extracts TID, sets it on the currently-active span.
     * The OTel agent's HTTP client span is still active at this point because
     * the OUT chain runs on the same thread as the HTTP send.
     */
    private static class TidCaptureCallback implements CachedOutputStreamCallback {

        @Override
        public void onFlush(CachedOutputStream cos) {
            // No-op — we only act on close, when the full envelope is written.
        }

        @Override
        public void onClose(CachedOutputStream cos) {
            try {
                StringBuilder envelope = new StringBuilder();
                cos.writeCacheTo(envelope);
                Matcher m = TID_PATTERN.matcher(envelope);
                if (m.find()) {
                    String tid = m.group(1);
                    Span.current().setAttribute("tid", tid);
                    log.info("OTel SOAP extension — captured tid={}", tid);
                } else {
                    log.debug("OTel SOAP extension — no <TID> in outgoing envelope ({} bytes)",
                            envelope.length());
                }
            } catch (IOException e) {
                log.debug("OTel SOAP extension — could not read cached envelope: {}",
                        e.getMessage());
            }
        }
    }
}
