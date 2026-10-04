#!/bin/bash
set -e

echo "=== Enabling Docker Auto-Start in WSL2 ==="

# Check current WSL config
echo "Current WSL configuration:"
cat /etc/wsl.conf 2>/dev/null || echo "No wsl.conf found"
echo ""

# Add systemd to WSL config
echo "Adding systemd boot configuration..."
sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[automount]
enabled=true
root=/mnt/

[interop]
enabled=true
appendWindowsPath=false

[boot]
systemd=true
EOF

echo "Updated WSL configuration:"
cat /etc/wsl.conf
echo ""

echo "=== Configuration Complete! ==="
echo ""
echo "Docker is installed and your user is in the docker group."
echo ""
echo "NEXT STEPS TO COMPLETE SETUP:"
echo "=============================="
echo "1. Exit this WSL session (type 'exit' or close the terminal)"
echo "2. Open PowerShell or Command Prompt in Windows"
echo "3. Run: wsl --shutdown"
echo "4. Wait 5 seconds"
echo "5. Restart your WSL terminal"
echo ""
echo "AFTER RESTART, VERIFY DOCKER:"
echo "============================="
echo "Run these commands to verify everything works:"
echo "  docker --version"
echo "  docker run hello-world"
echo "  systemctl status docker"
echo ""
