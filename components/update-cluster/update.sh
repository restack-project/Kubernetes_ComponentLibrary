#!/bin/bash

# Parameters
NODE_LIST="$1"
IP_LIST="$2"
KUBECONFIG="$3"
USER="$4"
UPDATE_COMMAND="$5"
SSH_PRIVATE_KEY="${6:-id_rsa}"

IFS=', ' read -r -a KUBE_NODE_LIST <<< "$NODE_LIST"
IFS=', ' read -r -a KUBE_NODE_IP_LIST <<< "$IP_LIST"

# Functions
drain_node() {
  local node="$1"
  echo "Draining node $node"
  drain_output=$(KUBECONFIG="$KUBECONFIG" kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --force --grace-period=60 2>&1)
  echo "$drain_output"

  local exit_status=$?
  if [[ $exit_status -ne 0 ]]; then
    echo "Failed to drain node: $node"
    exit 1
  else
    echo "Node drained: $node"
  fi
}

uncordon_node() {
  local node="$1"
  echo "Uncordoning node: $node"
  uncordon_output=$(KUBECONFIG="$KUBECONFIG" kubectl uncordon "$node" 2>&1)
  echo "$uncordon_output"

  local exit_status=$?
  if [[ $exit_status -ne 0 ]]; then
    echo "Failed to uncordon node: $node"
  else
    echo "Node uncordoned: $node"
  fi
}

update_node() {
  local node="$1"
  echo "Updating node: $node"
  update_output=$(ssh -i "$SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no "$USER"@"$node" "$UPDATE_COMMAND" 2>&1)
  echo "$update_output"

  local exit_status=$?
  if [[ $exit_status -ne 0 ]]; then
      echo "Node update failed. Error: $update_output"
      exit 1
  else
      echo "Node updated: $node"
  fi
}

# Run
for i in "${!KUBE_NODE_LIST[@]}"; do
  node="${KUBE_NODE_LIST[$i]}"
  ip="${KUBE_NODE_IP_LIST[$i]}"
  drain_node "$node"
  sleep 5
  update_node "$ip"
  sleep 5
  uncordon_node "$node"
  sleep 5
done

exit 0
