#!/bin/bash

set -e

handle_error() {
    echo "❌ Error: $1"
    exit 1
}

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    armv7l)  arch="arm"   ;;
    riscv64) arch="riscv64" ;;
    *) handle_error "Unsupported architecture: $arch" ;;
esac

k8s_server_version=$(curl -sk https://127.0.0.1:6443/version | awk -F'"' '/gitVersion/{print $4}' | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)

wget -O /usr/local/bin/kubectl https://dl.k8s.io/$k8s_server_version/bin/$os/$arch/kubectl
mkdir -p ~/.kube && ln -s /var/lib/kubesolo/pki/admin/admin.kubeconfig ~/.kube/config
chmod +x /usr/local/bin/kubectl
kubectl version

exit 0
