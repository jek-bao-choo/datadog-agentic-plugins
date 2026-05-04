#!/usr/bin/env bash
#
# install.sh — copy this skill's references/ project to a CentOS 9 EC2 instance
# and build the JAR. Does NOT start the SOAP client — starting requires an
# interactive SSH session (foreground or `nohup ... </dev/null & disown ; exit`
# from your own terminal). Same rationale as setup-springboot3x-soap:
# backgrounding from a single-shot SSH command is unreliable.
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
REMOTE_DIR="${REMOTE_DIR:-/opt/cargostream/soap-client}"
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
  ls -lh target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar
"

cat <<EOF

Build complete. The JAR is at $REMOTE_DIR/target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar
on the EC2 host.

Prerequisites for starting App A:
  - App B must be running on port 8084 (from setup-springboot3x-soap).
    Verify: ssh -i $SSH_KEY $SSH_USER@$EC2_IP \\
      'curl -sf http://localhost:8084/actuator/health'

To start App A, open an SSH session and run it in foreground:

  ssh -i $SSH_KEY $SSH_USER@$EC2_IP
  cd $REMOTE_DIR
  java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar

Boot takes ~7-10 s. Look for "Started Springboot3xCamelSoapApplication in N seconds"
and "Started submit-shipment (rest:/jek-trigger)".

Trigger an end-to-end SOAP call from your laptop:

  curl -sS -X POST http://$EC2_IP:8083/jek-trigger \\
    -H 'Content-Type: application/json' \\
    -d '{"tid":"tid-trigger-001","payload":"hello-from-app-a"}'

Expected response (App B's SOAP response, marshaled to JSON):
  {"tid":"tid-trigger-001","status":"received","received_at":"<ISO 8601>"}

For longer-running runs (e.g. while testing OTel auto-injection), background
the JVM from inside the interactive SSH session — NOT from a single-shot SSH
command:

  cd $REMOTE_DIR
  nohup java -jar target/springboot3x-camel-soap-0.0.1-SNAPSHOT.jar </dev/null \\
    >$LOG_DIR/soap-client.stdout.log 2>&1 &
  disown
  exit  # safe to close SSH; disown'd job survives

Logs:
  Console + Logback FILE appender: $LOG_DIR/soap-client.log (rotates daily)
  Stdout (only when launched with the nohup snippet above): $LOG_DIR/soap-client.stdout.log

Tail logs from your laptop:
  ssh -i $SSH_KEY $SSH_USER@$EC2_IP 'tail -f $LOG_DIR/soap-client.log'
EOF
