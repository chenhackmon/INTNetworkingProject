#!/bin/bash

# Ensure correct usage
if [ $# -ne 1 ]; then
  echo "Usage: $0 <private-instance-ip>"
  exit 1
fi

# Variables
PRIVATE_IP=$1
NEW_KEY_PATH="$HOME/.ssh/id_rsa_new"
PUBLIC_KEY_PATH="$NEW_KEY_PATH.pub"
OLD_KEY_PATH="$HOME/.ssh/id_rsa"

# Generate a new SSH key pair
echo "Generating new SSH key pair..."
ssh-keygen -t rsa -b 4096 -f $NEW_KEY_PATH -N ""
chmod 600 $NEW_KEY_PATH

# Copy the new public key to the authorized_keys on the private instance
NEW_PUBLIC_KEY=$(cat $PUBLIC_KEY_PATH)
echo "Adding new public key to the private instance..."
ssh -i "$OLD_KEY_PATH" ubuntu@$PRIVATE_IP "echo '$NEW_PUBLIC_KEY' >> ~/.ssh/authorized_keys"

# Verify the new key works
echo "Verifying new key..."
ssh -i "$NEW_KEY_PATH" ubuntu@$PRIVATE_IP 'exit'
if [ $? -ne 0 ]; then
  echo "Failed to connect to the private instance using the new key."
  exit 1
fi

# Remove the old key from authorized_keys on the private instance
OLD_PUBLIC_KEY=$(cat $OLD_KEY_PATH.pub)
ESCAPED_OLD_KEY=$(echo "$OLD_PUBLIC_KEY" | sed 's/[\/&]/\\&/g')
echo "Removing old public key from the private instance..."
ssh -i "$NEW_KEY_PATH" ubuntu@$PRIVATE_IP "sed -i '/$ESCAPED_OLD_KEY/d' ~/.ssh/authorized_keys"

# Verify the old key no longer works
echo "Verifying old key removal..."
ssh -i "$OLD_KEY_PATH" ubuntu@$PRIVATE_IP 'exit'
if [ $? -eq 0 ]; then
  echo "Old key is still valid, which shouldn't be the case."
  exit 1
fi

# Remove old key from the public instance
echo "Cleaning up old keys..."
rm -f $OLD_KEY_PATH $OLD_KEY_PATH.pub

# Replace the old key with the new key locally
echo "Updating local keys..."
mv $NEW_KEY_PATH $HOME/.ssh/id_rsa
mv $PUBLIC_KEY_PATH $HOME/.ssh/id_rsa.pub

echo "SSH key rotation completed successfully."
