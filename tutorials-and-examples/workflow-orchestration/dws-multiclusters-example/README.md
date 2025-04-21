# Multikueue-dws-integration

This repository provides the files needed to demonstrate how to use MultiKueue
with Dynamic Workload Scheduler (DWS) GKE Autopilot. This setup allows you to
run workloads across multiple GKE clusters in different regions, automatically
leveraging available GPU resources thanks to DWS.

## Repository Contents

This repository contains the following files:

*   `create-clusters.sh`: Script to create the required GKE clusters (one
    manager and three workers).
*   `tf folder`: contains the terraform script to create the required GKE
    clusters (one manager and three workers). You can use it instead of the bash
    script.
*   `deploy-multikueue.sh`: Script to install and configure Kueue and MultiKueue
    on the clusters.
*   `dws-multi-worker.yaml`: Kueue configuration for the worker clusters,
    including manager configuration.
*   `annotate-ksa-authentication.sh`: Script to annotate KSA to enable Workload
    Identity Federation.
*   `pubsub_worker_deployment.yaml`: Example deployment mimicking a inference
    worker to be submitted to the MultiKueue setup.
*   `hpa.yaml`: Example Horizontal Pod Autoscaler definition using
    [Kubernetes Event-driven Autoscaling](https://cloud.google.com/stackdriver/docs/managed-prometheus/hpa#stackdriver-adapter)
    using custom metrics of Cloud Pub/Sub

## Setup and Usage

### Create Clusters

```
terraform -chdir=tf init
terraform -chdir=tf plan
terraform -chdir=tf apply -var project_id=<YOUR PROJECT ID>
```

### Install Kueue

After creating the GKE clusters and updating your kubeconfig files, install the
Kueue components:

```
./deploy-multikueue.sh
```

### Validate installation

Verify the Kueue installation and the connection between the manager and worker
clusters:

```
kubectl get clusterqueues dws-cluster-queue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}CQ - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get admissionchecks sample-dws-multikueue -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}AC - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get multikueuecluster multikueue-dws-worker-asia -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}MC-ASIA - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get multikueuecluster multikueue-dws-worker-us -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}MC-US - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
kubectl get multikueuecluster multikueue-dws-worker-eu -o jsonpath="{range .status.conditions[?(@.type == \"Active\")]}MC-EU - Active: {@.status} Reason: {@.reason} Message: {@.message}{'\n'}{end}"
```

A successful output should look like this:

```
CQ - Active: True Reason: Ready Message: Can admit new workloads
AC - Active: True Reason: Active Message: The admission check is active
MC-ASIA - Active: True Reason: Active Message: Connected
MC-US - Active: True Reason: Active Message: Connected
MC-EU - Active: True Reason: Active Message: Connected
```

### Rollout example deployment

Create Pub/Sub to be used by the workers:

```
# worker will listen to subscription-1 for work
gcloud pubsub topics create topic-1
gcloud pubsub subscriptions create subscription-1 --topic=topic-1
# worker will publish to topic-2 when work is finished
gcloud pubsub topics create topic-2
gcloud pubsub subscriptions create subscription-2 --topic=topic-2
```

Annotate KSA to enable Workload Identity Federation:

```
./annotate-ksa-authentication.sh
```

Update the PROJECT_ID environment variable in `pubsub_worker_deployment.yaml`,
then submit the example deployment to the Kueue controller, which will run it on
a worker cluster with available resources:

```
kubectl create -f pubsub_worker_deployment.yaml
```

### Run the example and see it work in action

You can publish some messages to `topic-1` which mimic scheduling of work:

```
./publish_message.sh
```

You should be able to see in logs of worker pod that messages are being
processed. As unacked messages accumulate in the subscription, the HPA will
scale up and pods will be scheduled in cluster with available quotas.

### Destroy resources

```
terraform -chdir=tf destroy -var project_id=<YOUR PROJECT ID>
```
