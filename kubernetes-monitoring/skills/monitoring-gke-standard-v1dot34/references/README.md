## Install the Datadog Operator

```bash
helm repo add datadog https://helm.datadoghq.com
helm install datadog-operator datadog/datadog-operator
kubectl create secret generic datadog-secret --from-literal api-key=<replace_with-datadog_api_key>
```

## Update the datadog-agent.yaml file
```bash
sudo vim datadog-agent.yaml
```

## Deploy the Agent with the above configuration file
```bash
kubectl apply -f datadog-agent.yaml
```

## Check status
```bash
kubectl get pods
```
![](../assets/proof-datadog-agent-operator.png)

## Troubleshooting

### Cluster must have internet egress

The Datadog Agent requires outbound internet access to reach Datadog intake endpoints (e.g. `*.datadoghq.com`). On GKE private clusters where nodes lack external IPs, you must configure **Cloud NAT** to provide egress:

```bash
# Create a Cloud Router
gcloud compute routers create <ROUTER_NAME> \
  --network=<VPC_NAME> \
  --region=<REGION>

# Create a Cloud NAT configuration
gcloud compute routers nats create <NAT_NAME> \
  --router=<ROUTER_NAME> \
  --region=<REGION> \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges
```

Without egress, agent logs will show `i/o timeout` or `Client.Timeout exceeded` errors for all Datadog endpoints.

### Set `clusterName` to the actual GKE cluster name

In `datadog-agent.yaml`, replace the placeholder `clusterName` value with your actual GKE cluster name so metrics are correctly tagged in Datadog:

```yaml
spec:
  global:
    clusterName: "your-actual-cluster-name"
```

You can find your cluster name with:
```bash
gcloud container clusters list --format="value(name)"
```