#!/bin/bash

# Existing script commands...

# Initialize Kubernetes Cluster with kubeadm
echo "Initializing Kubernetes Cluster..."
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.27.11 >~/join.txt 2>&1
if [ $? -ne 0 ]; then
    echo "Error: kubeadm init failed. Exiting..."
    exit 1
else
    echo "Join the worker nodes using kubeadm join command"
fi

# Set kubectl access
echo "Setting kubectl access..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy kubeconfig file. Exiting..."
    exit 1
fi

# Change ownership of the kubeconfig file
sudo chown $(id -u):$(id -g) $HOME/.kube/config
if [ $? -ne 0 ]; then
    echo "Error: Failed to change ownership of kubeconfig file. Exiting..."
    exit 1
fi

# Apply Calico CNI for networking
echo "Applying Calico CNI for networking..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
if [ $? -ne 0 ]; then
    echo "Error: Failed to apply Calico CNI. Exiting..."
    exit 1
fi

echo "Kubernetes Cluster Initialized and Calico CNI Applied Successfully!"
