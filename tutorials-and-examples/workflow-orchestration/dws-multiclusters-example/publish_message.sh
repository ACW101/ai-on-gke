#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# --- Configuration ---
PROJECT_ID=$(gcloud config get-value project)
TOPIC_ID="topic-1" # Replace with the name of your Pub/Sub topic
MESSAGE_PREFIX="Hello from the script - Message"
NUM_MESSAGES=100                 # Number of messages to publish
SLEEP_INTERVAL=2                # Seconds to wait between publishing messages

# --- Function to publish a message ---
publish_message() {
  local message="$1"
  local message_encoded=$(echo -n "$message" | base64)

  echo "Publishing message: '$message'..."
  gcloud pubsub topics publish "$TOPIC_ID" --project="$PROJECT_ID" --message="$message_encoded"

  if [ $? -eq 0 ]; then
    echo "Successfully published."
  else
    echo "Error publishing message."
  fi
}

# --- Main loop ---
echo "Starting to publish $NUM_MESSAGES messages to topic '$TOPIC_ID' in project '$PROJECT_ID'..."

for i in $(seq 1 "$NUM_MESSAGES"); do
  current_message="${MESSAGE_PREFIX} $i"
  publish_message "$current_message"
  sleep "$SLEEP_INTERVAL"
done

echo "Finished publishing messages."
