#!/bin/bash

KUBESOLOCTL_PATH=$(which kubesoloctl 2>/dev/null)
if [ -n "$KUBESOLOCTL_PATH" ] && [ -f "$KUBESOLOCTL_PATH" ]; then
    echo "🗑️  Removing kubesoloctl binary: $KUBESOLOCTL_PATH"
    rm -f "$KUBESOLOCTL_PATH"
    echo "✅  Removed kubesoloctl binary"
else
    echo "🔔  kubesoloctl binary not found"
    exit 0
fi

echo "🔍  Validating kubesoloctl uninstallation ..."
if command -v kubesoloctl &> /dev/null; then
    echo "❌  kubesoloctl is still available"
    exit 1
else
    echo "✅  kubesoloctl has been uninstalled"
fi

echo "🎉  kubesoloctl uninstallation completed successfully!"
exit 0
