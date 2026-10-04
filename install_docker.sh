#!/bin/bash
set -e

echo "=== Installing Docker on Ubuntu 24.04 (WSL2) ==="

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists again
echo "Updating package lists with Docker repository..."
sudo apt-get update

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Enable Docker service
echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Configure WSL2 for systemd
echo "Configuring WSL2 for systemd..."
if ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    echo '[boot]
systemd=true' | sudo tee -a /etc/wsl.conf
fi

echo ""
echo "=== Docker installation complete! ==="
echo ""
echo "IMPORTANT: You need to restart WSL2 for changes to take effect:"
echo "  1. Exit this WSL session"
echo "  2. In PowerShell/CMD, run: wsl --shutdown"
echo "  3. Restart WSL"
echo ""
echo "After restart, verify with: docker run hello-world"
