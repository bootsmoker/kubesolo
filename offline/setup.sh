#!/bin/bash

KUBESOLO_PATH="/var/lib/kubesolo"

check() {
    echo "📂  Check install.sh"
    if [ ! -f install.sh ]; then
        echo "❌  Error: install.sh not found!"
        exit 1
    fi
    echo "✅  Found install.sh"

    echo "📂  Check install-kubectl.sh"
    if [ ! -f install-kubectl.sh ]; then
        echo "❌  Error: install-kubectl.sh not found!"
        exit 1
    fi
    echo "✅  Found install-kubectl.sh"
}

install() {
    echo "📂  Looking for offline packages"
    files=$(ls -r kubesolo-*-offline.tar.gz 2>/dev/null)
    if [ -z "$files" ]; then
        echo "❌  Error: No packages found!"
        exit 1
    fi

    file_count=$(echo "$files" | wc -l)
    if [ $file_count -eq 1 ]; then
        selected="$files"
        echo "📦  Auto-selected: $selected"
    else
        echo "📦  Available packages:"
        echo "$files" | cat -n
        read -p "🔢  Select file number (or 0 to exit): " choice
        if [ "$choice" = "0" ]; then
            echo "🛑  Warning: Installation cancelled"
            exit 0
        fi
        selected=$(echo "$files" | sed -n "${choice}p")
        if [ -z "$selected" ]; then
            echo "❌  Error: Invalid selection!"
            exit 1
        fi
    fi

    echo "📋  Package $selected has been selected"
    echo "🚀  Installing $selected ..."
    # bash install.sh --apiserver-extra-sans="10.6.x.x,10.8.x.x,domain.an" \
    #     --offline-install=$selected \
    #     --path=$KUBESOLO_PATH \
    #     --local-storage=true \
    #     --debug=false
}

verify() {
    echo "🔍  Check kubesolo.service"
    if ! systemctl list-unit-files | grep -q kubesolo.service; then
        echo "❌  Error: kubesolo.service not found!"
        exit 1
    fi

    echo "⏳  Waiting for kubesolo service to start ..."
    local attempt=1
    while [ $attempt -le 120 ]; do
        if ss -lnt | grep -q ":6443 "; then
            echo "📡  Port 6443 is listening"
            if curl -s -k --max-time 5 https://127.0.0.1:6443/version > /dev/null 2>&1; then
                echo "✅  API service is ready"
                return 0
            else
                echo "🔔  API service not yet ready"
            fi
        fi
        ((attempt++))
        sleep 1
    done

    echo "❌  Error: kubesolo service startup timeout!"
    echo "🩺  Diagnostic information:"
    echo "📍  Service status:"
    echo "--------------------------------------------------------------------------------"
    systemctl status kubesolo.service --no-pager -l
    echo "--------------------------------------------------------------------------------"
    echo "📍  Recent logs:"
    echo "--------------------------------------------------------------------------------"
    journalctl -u kubesolo.service -n 30 --no-pager
    echo "--------------------------------------------------------------------------------"
    exit 1
}

check
install
verify

echo "🚀  Installing kubectl ..."
bash install-kubectl.sh $KUBESOLO_PATH

# Exit with success code
exit 0
