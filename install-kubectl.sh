#!/bin/bash

KUBESOLO_PATH="${1:-/var/lib/kubesolo}"
KUBECTL_PATH="/usr/local/bin/kubectl"

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    armv7l)  arch="arm"   ;;
    riscv64) arch="riscv64" ;;
    *) { echo "❌  Error: Unsupported architecture: $arch"; exit 1; } ;;
esac

k8s_server_version=$(curl -sk https://127.0.0.1:6443/version | awk -F'"' '/gitVersion/{print $4}' | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)

if [ -z "$k8s_server_version" ]; then
    echo "❌  Error: Failed to get Kubernetes server version"
    exit 1
fi

echo "📋  Required Kubernetes server version: $k8s_server_version"

if command -v kubectl &> /dev/null; then
    echo "📌  kubectl is already installed"

    current_version=$(kubectl version --client -o json 2>/dev/null | grep -o '"gitVersion":"v[0-9]\+\.[0-9]\+\.[0-9]\+"' | head -1 | cut -d'"' -f4)

    if [ -z "$current_version" ]; then
        current_version=$(kubectl version --client 2>/dev/null | grep -o 'Client Version: v[0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d' ' -f3)
    fi

    if [ -z "$current_version" ]; then
        echo "🔔  Unable to determine current kubectl version, will reinstall"
    else
        echo "📋  Current kubectl client version: $current_version"

        if [ "$current_version" = "$k8s_server_version" ]; then
            echo "✅  kubectl version is already up to date with server version"
            echo "🎉  All good!"
            exit 0
        else
            echo "💡  Version mismatch detected (Current: $current_version, Required: $k8s_server_version)"
            KUBECTL_PATH=$(which kubectl)
            if [ -f "$KUBECTL_PATH" ]; then
                echo "🗑️  Removing $KUBECTL_PATH"
                rm -f "$KUBECTL_PATH"
                echo "✅  Removed $KUBECTL_PATH"
            fi
        fi
    fi
else
    echo "📌  kubectl is not installed"
fi

echo "📥  Downloading kubectl $k8s_server_version for $os/$arch ..."
wget -q --show-progress -O $KUBECTL_PATH https://dl.k8s.io/$k8s_server_version/bin/$os/$arch/kubectl || { echo "❌  Error: Failed to download kubectl"; exit 1; }

chmod +x $KUBECTL_PATH
echo "✅  kubectl installed to $KUBECTL_PATH"

mkdir -p ~/.kube
if [ -f $KUBESOLO_PATH/pki/admin/admin.kubeconfig ]; then
    ln -sf $KUBESOLO_PATH/pki/admin/admin.kubeconfig ~/.kube/config
    echo "✅  kubeconfig symlink created"
else
    echo "🚨  Warning: admin.kubeconfig not found at $KUBESOLO_PATH/pki/admin/admin.kubeconfig"
fi

echo "🔍  Validating kubectl installation ..."
kubectl version --client

echo "🎉  kubectl installation completed successfully!"
exit 0
