#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

kubeconfigs=("worker-asia-southeast1" "worker-us-east4" "worker-europe-west4" "manager-europe-west4")
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
PREFIX_MANAGER="man"
PREFIX_WORKER="w"

for i in "${!kubeconfigs[@]}"; do
    config="${kubeconfigs[$i]}"
    kubectl config use-context $config

    kubectl annotate serviceaccount default "iam.gke.io/gcp-service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" --overwrite
done
