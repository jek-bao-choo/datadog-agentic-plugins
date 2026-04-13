package com.example.otelext;

import io.opentelemetry.api.trace.Span;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Servlet Filter that extracts transaction_id, airway_bill_id, and houseway_bill_id
 * from XML request bodies and adds them as OTel span attributes.
 *
 * How it works:
 * 1. Wraps the request to cache the body (so Spring MVC can still read it)
 * 2. Lets the normal processing happen (chain.doFilter)
 * 3. After processing, parses the cached XML body with regex
 * 4. Adds extracted values to the current OTel span via Span.current().setAttribute()
 *
 * No application code changes needed — loaded via Spring Boot auto-configuration
 * from an external JAR using -Dloader.path.
 */
public class XmlAttributeExtractorFilter implements Filter {

    private static final Pattern TX_ID = Pattern.compile("<transaction_id>([^<]+)</transaction_id>");
    private static final Pattern AWB_ID = Pattern.compile("<airway_bill_id>([^<]+)</airway_bill_id>");
    private static final Pattern HWB_ID = Pattern.compile("<houseway_bill_id>([^<]+)</houseway_bill_id>");

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        if (!(request instanceof HttpServletRequest httpReq)) {
            chain.doFilter(request, response);
            return;
        }

        // Only process XML requests to /jek-receive-xml
        String uri = httpReq.getRequestURI();
        String contentType = httpReq.getContentType();
        if (!uri.contains("/jek-receive-xml") || contentType == null || !contentType.contains("xml")) {
            chain.doFilter(request, response);
            return;
        }

        // Wrap request to cache the body (so Spring MVC's @RequestBody can still read it)
        CachedBodyRequest cachedRequest = new CachedBodyRequest(httpReq);

        // Let Spring MVC process the request normally
        chain.doFilter(cachedRequest, response);

        // After processing, extract IDs from the cached body and add to the current span
        String body = cachedRequest.getCachedBody();
        if (body != null && !body.isEmpty()) {
            Span span = Span.current();
            setIfPresent(span, "transaction_id", TX_ID, body);
            setIfPresent(span, "airway_bill_id", AWB_ID, body);
            setIfPresent(span, "houseway_bill_id", HWB_ID, body);
        }
    }

    private void setIfPresent(Span span, String attrName, Pattern pattern, String body) {
        Matcher m = pattern.matcher(body);
        if (m.find()) {
            span.setAttribute(attrName, m.group(1));
        }
    }

    /**
     * Request wrapper that caches the body so it can be read by both
     * this filter and by Spring MVC's @RequestBody deserialization.
     */
    static class CachedBodyRequest extends HttpServletRequestWrapper {
        private final byte[] cachedBody;

        CachedBodyRequest(HttpServletRequest request) throws IOException {
            super(request);
            this.cachedBody = request.getInputStream().readAllBytes();
        }

        @Override
        public jakarta.servlet.ServletInputStream getInputStream() {
            ByteArrayInputStream bais = new ByteArrayInputStream(cachedBody);
            return new jakarta.servlet.ServletInputStream() {
                @Override public int read() { return bais.read(); }
                @Override public boolean isFinished() { return bais.available() == 0; }
                @Override public boolean isReady() { return true; }
                @Override public void setReadListener(jakarta.servlet.ReadListener listener) {}
            };
        }

        @Override
        public BufferedReader getReader() {
            return new BufferedReader(new InputStreamReader(getInputStream(), StandardCharsets.UTF_8));
        }

        String getCachedBody() {
            return new String(cachedBody, StandardCharsets.UTF_8);
        }
    }
}
