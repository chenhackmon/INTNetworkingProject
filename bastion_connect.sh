#!/bin/bash

# Check if KEY_PATH environment variable is set
if [ -z "$KEY_PATH" ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

# Check the number of arguments
if [ "$#" -lt 1 ]; then
  echo "Please provide bastion IP address"
  exit 5
fi

# Assign variables
BASTION_IP=$1
PRIVATE_IP=$2
COMMAND=$3

# Ensure the .ssh directory exists
mkdir -p ~/.ssh

# Copy and set permissions for the key
cp "$KEY_PATH" ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa

# If only bastion IP is provided, connect to the bastion host
if [ -z "$PRIVATE_IP" ]; then
  ssh -i ~/.ssh/id_rsa ubuntu@"$BASTION_IP"
else
  # If both bastion IP and private IP are provided, connect to the private host through the bastion host
  if [ -z "$COMMAND" ]; then
    ssh -t -i ~/.ssh/id_rsa ubuntu@"$BASTION_IP" "ssh -i ~/.ssh/id_rsa ubuntu@$PRIVATE_IP"
  else
    ssh -t -i ~/.ssh/id_rsa ubuntu@"$BASTION_IP" "ssh -i ~/.ssh/id_rsa ubuntu@$PRIVATE_IP '$COMMAND'"
  fi
fi
