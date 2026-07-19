#!/bin/bash

set -e

handle_error() {
    echo "❌ Error: $1"
    exit 1
}

mkdir -p ~/kubesolo && cd ~/kubesolo || handle_error "Failed to create or enter directory ~/kubesolo"

echo "📥 Downloading KubeSolo installer..."
wget https://get.kubesolo.io -O install.sh && chmod +x install.sh || handle_error "Failed to download installer"
KUBESOLO_OFFLINE=true bash -x install.sh --download-only

echo "✅ KubeSolo download completed successfully!"
exit 0