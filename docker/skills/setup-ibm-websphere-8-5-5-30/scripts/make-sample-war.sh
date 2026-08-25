#!/usr/bin/env bash
# Build a throwaway WAR for smoke-testing a deployment, so section L can be exercised
# without a real application to hand.
#
#   ./make-sample-war.sh [output.war]      # default: ./sample.war
#
# The JSP echoes the server identity, servlet spec, context path, scheme, and port, so
# one GET confirms the app is live and reached through the transport you expected.
set -euo pipefail

OUT=${1:-sample.war}
OUT=$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT

mkdir -p "$BUILD/WEB-INF"

cat > "$BUILD/index.jsp" <<'JSP'
<%@ page contentType="text/html" %>
<html><body>
<h1>SAMPLE-WAR-OK</h1>
<p>server=<%= application.getServerInfo() %></p>
<p>servletSpec=<%= application.getMajorVersion() %>.<%= application.getMinorVersion() %></p>
<p>contextPath=<%= request.getContextPath() %></p>
<p>scheme=<%= request.getScheme() %> port=<%= request.getServerPort() %></p>
</body></html>
JSP

cat > "$BUILD/WEB-INF/web.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0" metadata-complete="false">
  <display-name>sample</display-name>
  <welcome-file-list><welcome-file>index.jsp</welcome-file></welcome-file-list>
</web-app>
XML

# No compiler needed - the JSP is translated on first request by the server.
rm -f "$OUT"
( cd "$BUILD" && zip -qr "$OUT" . )
echo "built $OUT"
unzip -l "$OUT"
