#!/bin/bash

KUBECTL_PATH=$(which kubectl 2>/dev/null)
if [ -n "$KUBECTL_PATH" ] && [ -f "$KUBECTL_PATH" ]; then
    echo "🗑️  Removing kubectl binary: $KUBECTL_PATH"
    rm -f "$KUBECTL_PATH"
    echo "✅  Removed kubectl binary"
else
    echo "🔔  kubectl binary not found"
    exit 0
fi

if [ -d "$HOME/.kube" ]; then
    if [ -n "$(ls -A "$HOME/.kube" 2>/dev/null)" ]; then
        echo "🚨  Warning: ~/.kube directory is not empty"
    fi
    rmdir "$HOME/.kube" 2>/dev/null && echo "✅  Removed ~/.kube directory" || echo "🚫  Could not remove ~/.kube directory"
fi

echo "🔍  Validating kubectl uninstallation ..."
if command -v kubectl &> /dev/null; then
    echo "❌  kubectl is still available"
    exit 1
else
    echo "✅  kubectl has been uninstalled"
fi

echo "🎉  kubectl uninstallation completed successfully!"
exit 0
