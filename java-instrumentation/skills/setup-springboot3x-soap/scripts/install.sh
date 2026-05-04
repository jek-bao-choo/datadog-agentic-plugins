#!/usr/bin/env bash
#
# install.sh — copy this skill's references/ project to a CentOS 9 EC2 instance
# and build the JAR. Does NOT start the SOAP server — starting requires an
# interactive SSH session (foreground or `nohup ... </dev/null &` from your own
# terminal). Background daemonization from a single-shot SSH command is not
# reliable: nohup'd processes get torn down with the SSH pty on session close,
# and the canonical pattern in this repo is to run Spring Boot apps in foreground
# from one SSH session and curl from another (matches `setup-springboot3x`).
#
# Usage: ./scripts/install.sh <EC2_PUBLIC_IP>
# Assumes ~/.ssh/jek_rsa_pem exists and the instance was provisioned by
# setup-ec2-centos9 (Java 17 + Maven preinstalled by user_data).

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <EC2_PUBLIC_IP>" >&2
  exit 1
fi

EC2_IP="$1"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/jek_rsa_pem}"
SSH_USER="${SSH_USER:-ec2-user}"
REMOTE_DIR="${REMOTE_DIR:-/opt/cargostream/soap-server}"
LOG_DIR="${LOG_DIR:-/var/log/cargostream}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Preparing remote directories on $EC2_IP"
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "
  sudo mkdir -p $REMOTE_DIR $LOG_DIR
  sudo chown -R $SSH_USER:$SSH_USER /opt/cargostream $LOG_DIR
"

echo "==> Copying references/ to $REMOTE_DIR"
scp -i "$SSH_KEY" -r "$SKILL_ROOT/references/." "$SSH_USER@$EC2_IP:$REMOTE_DIR/"

echo "==> Building with Maven on EC2 (this can take 1-2 minutes on first run)"
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_IP" "
  cd $REMOTE_DIR
  mvn -q clean package -DskipTests
  ls -lh target/springboot3x-soap-0.0.1-SNAPSHOT.jar
"

cat <<EOF

Build complete. The JAR is at $REMOTE_DIR/target/springboot3x-soap-0.0.1-SNAPSHOT.jar
on the EC2 host.

To start the SOAP server, open an SSH session and run it in foreground:

  ssh -i $SSH_KEY $SSH_USER@$EC2_IP
  cd $REMOTE_DIR
  java -jar target/springboot3x-soap-0.0.1-SNAPSHOT.jar

Boot takes ~7-10 s. Look for "Started Springboot3xSoapApplication in N seconds".
Leave that session open and use a second SSH session (or your laptop) to test:

  curl -sS http://$EC2_IP:8084/actuator/health
  curl -sS 'http://$EC2_IP:8084/ws/webmethods?wsdl' | head -30
  curl -sS -X POST http://$EC2_IP:8084/ws/webmethods \\
    -H 'Content-Type: text/xml; charset=utf-8' \\
    -H 'SOAPAction: ""' \\
    -d '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wm="http://example.com/webmethods">
          <soapenv:Body>
            <wm:submitShipment><TID>tid-smoke-001</TID><payload>hello</payload></wm:submitShipment>
          </soapenv:Body>
        </soapenv:Envelope>'

For longer-running runs (e.g. while testing OTel auto-injection), background
the JVM from inside the interactive SSH session — NOT from a single-shot SSH
command:

  cd $REMOTE_DIR
  nohup java -jar target/springboot3x-soap-0.0.1-SNAPSHOT.jar </dev/null \\
    >$LOG_DIR/soap-server.stdout.log 2>&1 &
  disown
  exit  # safe to close SSH; disown'd job survives

Logs:
  Console + Logback FILE appender: $LOG_DIR/soap-server.log (rotates daily)
  Stdout (only when launched with the nohup snippet above): $LOG_DIR/soap-server.stdout.log

Tail logs from your laptop:
  ssh -i $SSH_KEY $SSH_USER@$EC2_IP 'tail -f $LOG_DIR/soap-server.log'
EOF
