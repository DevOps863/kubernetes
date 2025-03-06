# Run the script on master node and the worker nodes.
#!/bin/bash

# Function to check the exit status of the last command and exit if it failed
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting..."
        exit 1
    fi
}

# Log in to the control plane node (assumed this part is already done)

# Step 1: Create the configuration file for containerd
echo "Creating containerd configuration file..."
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
check_error "Creating containerd configuration file"

# Step 2: Load the modules
echo "Loading overlay and br_netfilter modules..."
sudo modprobe overlay
check_error "Loading overlay module"
sudo modprobe br_netfilter
check_error "Loading br_netfilter module"

# Step 3: Set the system configurations for Kubernetes networking
echo "Setting system configurations for Kubernetes networking..."
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
check_error "Setting system configurations for Kubernetes networking"

# Step 4: Apply the new settings
echo "Applying new system settings..."
sudo sysctl --system
check_error "Applying system settings"

echo "Adding containerd repository..."
curl -sSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
check_error "Adding Docker GPG key"

echo "Adding Docker repository for containerd..."
echo "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
check_error "Adding Docker repository"

# Step 5: Install containerd
echo "Installing containerd..."
sudo apt-get update && sudo apt-get install -y containerd.io
check_error "Installing containerd"

# Step 6: Create the default containerd configuration file
echo "Creating default containerd configuration directory..."
sudo mkdir -p /etc/containerd
check_error "Creating containerd configuration directory"

# Step 7: Generate and save the default containerd configuration
echo "Generating containerd default configuration..."
sudo containerd config default | sudo tee /etc/containerd/config.toml
check_error "Generating containerd default configuration"

# Step 8: Restart containerd
echo "Restarting containerd..."
sudo systemctl restart containerd
check_error "Restarting containerd"

# Step 9: Verify containerd is running
echo "Verifying containerd status..."
sudo systemctl status containerd >>/dev/null
check_error "Verifying containerd status"

# Step 10: Disable swap
echo "Disabling swap..."
sudo swapoff -a
check_error "Disabling swap"

# Step 11: Install dependency packages
echo "Installing dependency packages..."
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
check_error "Installing dependency packages"

# Step 12: Download and add the Kubernetes GPG key
echo "Adding Kubernetes GPG key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
check_error "Adding Kubernetes GPG key"

# Step 13: Add Kubernetes to the repository list
echo "Adding Kubernetes repository to sources list..."
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [trusted=yes] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /
EOF
check_error "Adding Kubernetes repository"

# Step 14: Update package listings
echo "Updating package listings..."
sudo apt-get update
check_error "Updating package listings"

# Step 15: Install Kubernetes packages
echo "Installing Kubernetes packages (kubelet, kubeadm, kubectl)..."
sudo apt-get install -y kubelet kubeadm kubectl
check_error "Installing Kubernetes packages"

# Step 16: Turn off automatic updates
echo "Turning off automatic updates for Kubernetes packages..."
sudo apt-mark hold kubelet kubeadm kubectl
check_error "Turning off automatic updates for Kubernetes packages"

echo "Setup complete."
