#!/bin/bash

# Add Docker's official GPG key:
echo "Updating Repositories..."
sudo apt update > /dev/null 2>&1

# Check the exit status of the last command
if [ $? -ne 0 ]; then
    echo "Error: Failed to update repositories. Please check your network connection."
    exit 1 # Exit with a non-zero status to indicate an error
else
    echo "Repositories updated successfully."
fi

echo "Installing necessary packages..."
sudo apt-get install ca-certificates curl -y > /dev/null 2>&1

echo "Downloading keyrings..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

if [ $? -ne 0 ]; then
    echo "Error: Failed to download keyring. Aborting installation."
    exit 1 # Exit with a non-zero status to indicate an error
fi

sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo "Installing Docker..."
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Error: Failed to install all necessary packages. Aborting installation."
    exit 1 # Exit with a non-zero status to indicate an error
else
    echo "Docker has installed successfully."
fi