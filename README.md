# datadog-agentic-plugins

A marketplace of agentic plugins and skills that empower coding agents to set up and configure Datadog for a PoC. Not endorsed by Datadog. The plugins are unofficial and reflect my personal understanding of agentic coding plugins.

## Project Structure

```
datadog-agentic-plugins/
├── linux-monitoring/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── monitoring-ec2-ubuntu-v22/
│       │   └── SKILL.md
│       └── monitoring-gce-ubuntu-v24/
│           └── SKILL.md
│
├── kubernetes-monitoring/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       ├── monitoring-gke-standard-v1dot32/
│       │   └── SKILL.md
│       └── monitoring-eks-fargate-v1dot34/
│           └── SKILL.md
│
├── javascript-instrumentation/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       └── next-v15dot5-react-v19dot1/
│           └── SKILL.md
│
├── csharp-lambda-instrumentation/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── skills/
│       └── dotnet10-al2023-lambda-native-aot/
│           └── SKILL.md
```
