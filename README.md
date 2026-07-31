# PiggyMetrics Kubernetes CI/CD Setup

This repository contains the infrastructure-as-code and CI/CD pipelines to deploy the PiggyMetrics microservices architecture to a local Kubernetes cluster using a Blue-Green deployment strategy.

## Prerequisites
* Docker installed and running
* `kind` (Kubernetes in Docker) installed
* `kubectl` CLI installed
* Jenkins running (locally or containerized) with Docker and Kubectl tools installed.

## 1. Cluster Setup
Run the setup script to provision the local Kind cluster:
\`\`\`bash
chmod +x setup-kind.sh
./setup-kind.sh
\`\`\`

## 2. Base Infrastructure
Before deploying microservices, deploy the stateful backing services (MongoDB, RabbitMQ):
\`\`\`bash
kubectl apply -f k8s/base/mongodb.yaml
kubectl apply -f k8s/base/rabbitmq.yaml
\`\`\`
*(Note: Create standard deployments/services for these in your base folder).*

## 3. Jenkins Configuration
1. Install the **Docker Pipeline** and **Kubernetes CLI** plugins in Jenkins.
2. Add your DockerHub credentials in Jenkins under `Manage Jenkins -> Credentials` with the ID `dockerhub-credentials`.
3. Create a new Pipeline job and point it to the `Jenkinsfile` in this repository.

## 4. Blue-Green Deployment Execution
When the Jenkins pipeline runs, it performs the following:
1. Compiles the Java Spring Boot app.
2. Builds and pushes the Docker image to the registry.
3. Queries Kubernetes to see if `blue` or `green` is currently active.
4. Deploys the new image to the *inactive* environment.
5. Verifies pod readiness.
6. Patches the Kubernetes Service selector to instantaneously switch traffic.

**To trigger a rollback manually or verify failure handling:**
If the `Deploy to Inactive Environment` stage fails (e.g., bad code causes a crash loop), the `post { failure }` block in the Jenkinsfile catches it. The Service selector is never updated, meaning user traffic safely remains on the old, working version.