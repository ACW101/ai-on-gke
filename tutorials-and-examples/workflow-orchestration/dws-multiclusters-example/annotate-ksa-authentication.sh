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

