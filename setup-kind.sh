#!/bin/bash
# Install Kind if not present, then create the cluster
echo "Creating Kind cluster for PiggyMetrics..."

cat <<EOF | kind create cluster --name piggymetrics --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
EOF

echo "Cluster created. Current context:"
kubectl cluster-info --context kind-piggymetrics