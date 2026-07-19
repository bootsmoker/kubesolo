#!/bin/bash

KUBESOLOCTL_PATH="/usr/local/bin/kubesoloctl"

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$arch" in
    x86_64)  arch="amd64" ;;
    aarch64) arch="arm64" ;;
    armv7l)  arch="arm"   ;;
    riscv64) arch="riscv64" ;;
    *) { echo "❌  Error: Unsupported architecture: $arch"; exit 1; } ;;
esac

(echo > /dev/tcp/linkease.net/5443) 2>/dev/null && __KSPEEDER_AVAILABLE__="true" || __KSPEEDER_AVAILABLE__="false"

convert_github_url() {
    local url="$1"

    if [[ "$__KSPEEDER_AVAILABLE__" == "true" ]]; then
        if [[ "$url" == https://raw.githubusercontent.com/* ]]; then
            echo "$url" | sed 's|raw.githubusercontent.com/\([^/]*/[^/]*\)/|gh.linkease.net:5443/\1/raw/|'
            return
        elif [[ "$url" == https://github.com/* ]]; then
            echo "${url/github.com/gh.linkease.net:5443}"
            return
        fi
    fi

    echo "$url"
}

kubesolo_version=$(curl -sk https://127.0.0.1:6443/version | awk -F'"' '/gitVersion/{print $4}' | sed -n 's/.*kubesolo-\(v[0-9]\+\.[0-9]\+\.[0-9]\+\)/\1/p')

if [ -z "$kubesolo_version" ]; then
    echo "🔔  No version found in cluster, fetching latest release..."
    kubesolo_version=$(curl -s https://api.github.com/repos/portainer/kubesolo/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/v\1/')
    
    if [ -z "$kubesolo_version" ]; then
        echo "❌  Error: Failed to get latest version from GitHub"
        exit 1
    fi
    echo "📋  Using latest version: $kubesolo_version"
fi

echo "📥  Downloading kubesoloctl $kubesolo_version for $os/$arch ..."
wget -q --show-progress -O $KUBESOLOCTL_PATH "$(convert_github_url "https://github.com/portainer/kubesolo/releases/download/$kubesolo_version/kubesoloctl-$os-$arch")" || { echo "❌  Error: Failed to download kubesoloctl"; exit 1; }

chmod +x $KUBESOLOCTL_PATH
echo "✅  kubesoloctl installed to $KUBESOLOCTL_PATH"

echo "🔍  Validating kubesoloctl installation ..."
kubesoloctl version

echo "🎉  kubesoloctl installation completed successfully!"
exit 0
