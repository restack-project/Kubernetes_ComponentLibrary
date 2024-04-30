#!/bin/bash

# Parameters
DOCKER_HOST="$1"  
USER="$2"
COMPOSE_LOCATION="$3"
SSH_PRIVATE_KEY="${4:-id_rsa}"

execute_command_on_machine() {
  local command="$1"

  output=$(ssh -i "$SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no "$USER"@"$DOCKER_HOST" "$command" 2>&1)
  echo "$output"

  local exit_status=$?
  if [[ $exit_status -ne 0 ]]; then
    >&2 echo "Error executing command on machine ($exit_status): $command"
    exit 1
  fi
}

update_stack() {
  execute_command_on_machine "docker compose -f $COMPOSE_LOCATION/docker-compose.yaml down"
  execute_command_on_machine "docker compose -f $COMPOSE_LOCATION/docker-compose.yaml pull"
  execute_command_on_machine "docker compose -f $COMPOSE_LOCATION/docker-compose.yaml up -d"
  execute_command_on_machine "docker ps"
}

## Run
update_stack
exit 0
