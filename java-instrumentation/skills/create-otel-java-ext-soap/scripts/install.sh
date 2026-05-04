#!/usr/bin/env bash
#
# install.sh — copy this skill's references/ project to a CentOS 9 EC2 instance,
# build the OTel Java extension JAR, and stage it in /opt/otel/extensions/.
#
# Usage: ./scripts/install.sh <EC2_PUBLIC_IP>

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <EC2_PUBLIC_IP>" >&2
  exit 1
fi

EC2_IP="$1"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/jek_rsa_pem}"
SSH_USER="${SSH_USER:-ec2-user}"
SRC_DIR="${SRC_DIR:-/opt/otel/extensions-src/soap-tid}"
EXT_DIR="${EXT_DIR:-/opt/otel/extensions}"
JAR_NAME="otel-extension-soap-tid-1.0.jar"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Preparing remote directories on $EC2_IP"
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "
  sudo mkdir -p $SRC_DIR $EXT_DIR
  sudo chown -R $SSH_USER:$SSH_USER /opt/otel
"

echo "==> Copying references/ to $SRC_DIR"
scp -i "$SSH_KEY" -r "$SKILL_ROOT/references/." "$SSH_USER@$EC2_IP:$SRC_DIR/"

echo "==> Building extension JAR with Maven (~30 s with cached deps)"
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "
  cd $SRC_DIR
  mvn -q clean package
  ls -lh target/$JAR_NAME
"

echo "==> Staging the JAR in $EXT_DIR"
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "
  cp $SRC_DIR/target/$JAR_NAME $EXT_DIR/
  ls -lh $EXT_DIR/
"

echo "==> Verifying JAR contents"
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "
  jar tf $EXT_DIR/$JAR_NAME | grep -E 'SoapTidOutInterceptor|SoapTidAutoConfiguration|opentelemetry/api/trace/Span|AutoConfiguration\\.imports' | head -10
"

cat <<EOF

Extension built and staged.

To activate it on App A:

  1. Confirm App B is running:
       ssh -i $SSH_KEY $SSH_USER@$EC2_IP \\
         'curl -sf http://localhost:8084/actuator/health'

  2. Confirm the OTel Java Agent is installed system-wide
     (springboot3x-otel-java-tool-opt). Verify with:
       ssh -i $SSH_KEY $SSH_USER@$EC2_IP 'env | grep JAVA_TOOL_OPTIONS'

  3. (Re)start App A with -Dloader.path:
       ssh -i $SSH_KEY $SSH_USER@$EC2_IP
       cd /opt/cargostream/soap-client
       java -Dloader.path=$EXT_DIR/ \\
            -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar

     Look for this line on startup:
       INFO  c.e.o.SoapTidAutoConfiguration - OTel SOAP extension — registered SoapTidOutInterceptor on default Bus

  4. Trigger a SOAP call:
       curl -sS -X POST http://$EC2_IP:8083/jek-trigger \\
         -H 'Content-Type: application/json' \\
         -d '{"tid":"tid-ext-001","payload":"hello"}'

     Check the OTel Collector debug exporter log for the App A client span
     with attribute  tid: tid-ext-001:
       ssh -i $SSH_KEY $SSH_USER@$EC2_IP \\
         'sudo journalctl -u otelcol-contrib --since "30 seconds ago" --no-pager | grep -A 2 "tid"'

Full hand-off, including Datadog APM EU verification, is in
load-otel-java-ext / Phase 7 of stonebraker-TODO-java-instrumentation.md.
EOF
