#!/bin/bash

# Function to check if kubectl is installed
check_kubectl() {
  if ! command -v kubectl &> /dev/null
  then
    echo "kubectl not found. Please install it and try again."
    exit 1
  fi
}

# Function to check if virtctl is installed
install_virtctl() {
  if ! command -v virtctl &> /dev/null
  then
    echo "virtctl not found. Installing..."
    wget https://github.com/kubevirt/kubevirt/releases/latest/download/virtctl-linux-amd64
    chmod +x virtctl-linux-amd64
    sudo mv virtctl-linux-amd64 /usr/local/bin/virtctl
  else
    echo "virtctl already installed."
  fi
}

# Install KubeVirt
install_kubevirt() {
  echo "Creating KubeVirt namespace..."
  kubectl create namespace kubevirt

  echo "Installing KubeVirt operator..."
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/latest/download/kubevirt-operator.yaml

  echo "Installing KubeVirt custom resource (CR)..."
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/latest/download/kubevirt-cr.yaml

  echo "Waiting for KubeVirt components to be ready..."
  kubectl wait --for=condition=Available --timeout=600s -n kubevirt deployments --all
}

# Deploy VM
create_vm() {
  echo "Creating a VM manifest..."
  cat <<EOF > vm.yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
  namespace: default
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: testvm
    spec:
      domain:
        devices:
          disks:
            - disk:
                bus: virtio
              name: containerdisk
        resources:
          requests:
            memory: 512Mi
      volumes:
        - name: containerdisk
          containerDisk:
            image: kubevirt/cirros-container-disk-demo
EOF

  echo "Deploying the VM..."
  kubectl apply -f vm.yaml
}

# Start the VM
start_vm() {
  echo "Starting the VM..."
  kubectl patch virtualmachine testvm --type merge -p '{"spec":{"running":true}}'
}

# Access the VM console
access_vm_console() {
  echo "Accessing the VM console..."
  virtctl console testvm
}

# Main Script
check_kubectl
install_virtctl
install_kubevirt
create_vm
start_vm
access_vm_console
