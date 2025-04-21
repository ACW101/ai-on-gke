#!/bin/bash

# Copyright 2024 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

regions=("europe-west4" "asia-southeast1" "us-east4" "europe-west4")
kubeconfigs=("manager-europe-west4" "worker-asia-southeast1" "worker-us-east4" "worker-europe-west4")
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
PREFIX_MANAGER="man"
PREFIX_WORKER="w"

for i in "${!kubeconfigs[@]}"; do
    config="${kubeconfigs[$i]}"
    kubectl config use-context $config

    kubectl apply --force-conflicts --server-side -f kueue_manifest_v0.11.3.yaml
    if [[ $i -ne 0 ]]; then
        ./create-multikueue-kubeconfig.sh $config.kubeconfig
    fi
done
kubectl config use-context "${kubeconfigs[0]}"
for i in "${!kubeconfigs[@]}"; do
    if [[ $i -ne 0 ]]; then
        config="${kubeconfigs[$i]}"
        kubectl create secret generic $config-secret -n kueue-system --from-file=kubeconfig=$config.kubeconfig
    fi

done
kubectl wait --for=condition=available --timeout=600s deployment/kueue-controller-manager -n kueue-system
kubectl patch deployment kueue-controller-manager -n kueue-system --patch \
    '{"spec":{"template":{"spec":{"containers":[{"name":"manager","args":["--config=/controller_manager_config.yaml","--zap-log-level=8"]}]}}}}'
kubectl apply --server-side -f dws-multi.yaml

for i in "${!kubeconfigs[@]}"; do
    config="${kubeconfigs[$i]}"
    if [[ $i -ne 0 ]]; then
        kubectl config use-context $config
        kubectl wait --for=condition=available --timeout=600s deployment/kueue-controller-manager -n kueue-system
        kubectl apply --server-side -f dws-multi-worker.yaml
    fi
done

kubectl config use-context "${kubeconfigs[0]}"
kubectl rollout restart deployment -n kueue-system kueue-controller-manager
