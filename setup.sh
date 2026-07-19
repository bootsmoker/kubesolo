#!/bin/bash

DEFAULT_PATH="/var/lib/kubesolo"
KUBESOLO_PATH=""
KUBESOLO_SANS=""

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

    while true; do
        CONFIG_PATH=$(whiptail --inputbox "Please enter installation path:" 10 60 "$DEFAULT_PATH" --title "Modify" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            echo "🛑  Warning: Installation cancelled"
            exit 0
        fi

        if [ -z "$CONFIG_PATH" ]; then
            whiptail --msgbox "Path cannot be empty, please try again" 8 50 --title "Error"
            continue
        fi

        if whiptail --yesno "Install to $CONFIG_PATH?" 10 60 --title "Confirm"; then
            KUBESOLO_PATH="$CONFIG_PATH"
            break
        fi
    done
    echo "📋  Package will be installed to $KUBESOLO_PATH"

    echo "📡  Select available IP address and enter domain name"
    addresses=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
    if [ -z "$addresses" ]; then
        echo "❌  Error: No IPv4 addresses found!"
        exit 1
    fi

    IFS=$'\n' read -rd '' -a addr_array <<< "$addresses"
    IFS=',' read -ra existing_sans <<< "${KUBESOLO_SANS:-}"
    declare -A existing_set
    for existing in "${existing_sans[@]}"; do
        existing=$(echo "$existing" | xargs)
        if [ -n "$existing" ]; then
            existing_set["$existing"]=1
        fi
    done

    checklist_options=()
    for i in "${!addr_array[@]}"; do
        current_addr="${addr_array[$i]}"
        if [[ -z "${existing_set[$current_addr]}" ]]; then
            checklist_options+=("$i" "$current_addr" "OFF")
        fi
    done

    if [ ${#checklist_options[@]} -ne 0 ]; then
        selected_indices=$(whiptail --title "Select IP Addresses" \
            --checklist "Use ↑↓ to navigate, SPACE to select/deselect, ENTER to confirm" \
            20 60 10 \
            "${checklist_options[@]}" \
            3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            echo "🛑  Cancelled by user"
            exit 0
        fi

        if [ -n "$selected_indices" ]; then
            selected_addresses=()
            for idx in $selected_indices; do
                idx=$(echo "$idx" | tr -d '"')
                selected_addresses+=("${addr_array[$idx]}")
            done

            selected_ips_str=$(IFS=,; echo "${selected_addresses[*]}")
            echo "✅  Selected IP address: $selected_ips_str"

            if [ -n "$KUBESOLO_SANS" ]; then
                KUBESOLO_SANS="${KUBESOLO_SANS},${selected_ips_str}"
            else
                KUBESOLO_SANS="${selected_ips_str}"
            fi
            echo "📋  Updated KUBESOLO_SANS: $KUBESOLO_SANS"
        else
            echo "💡  No IP address selected"
        fi
    else
        echo "💡  No available IP addresses to select"
    fi

    echo "🌐  Enter domain names (optional)"
    echo "    - Press Enter to skip"
    echo "    - Single domain: example.com"
    echo "    - Multiple domains: example.com,api.example.com,k8s.example.com"
    read -p "👉  Enter domains (comma separated): " input_domains

    if [ -n "$input_domains" ]; then
        input_domains=$(echo "$input_domains" | sed 's/ //g')
        if [[ "$input_domains" =~ ^, ]] || [[ "$input_domains" =~ ,$ ]]; then
            echo "🚨  Warning: Invalid format (starts or ends with comma), cleaning up..."
            input_domains=$(echo "$input_domains" | sed 's/^,//;s/,$//')
        fi

        if [ -n "$input_domains" ]; then
            IFS=',' read -ra existing_sans <<< "$KUBESOLO_SANS"
            IFS=',' read -ra new_domains <<< "$input_domains"

            all_sans=("${existing_sans[@]}" "${new_domains[@]}")
            unique_sans=()
            for item in "${all_sans[@]}"; do
                item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [ -n "$item" ] && [[ ! " ${unique_sans[@]} " =~ " ${item} " ]]; then
                    unique_sans+=("$item")
                fi
            done

            echo "✅  Added domains: $input_domains"
            KUBESOLO_SANS=$(IFS=,; echo "${unique_sans[*]}")
        fi
        echo "📋  Updated KUBESOLO_SANS: $KUBESOLO_SANS"
    else
        echo "💡  No domains added"
    fi

    echo "🚀  Installing $selected ..."
    echo "    --apiserver-extra-sans: $KUBESOLO_SANS"
    echo "    --path: $KUBESOLO_PATH"
    bash install.sh --apiserver-extra-sans=$KUBESOLO_SANS \
        --offline-install=$selected \
        --path=$KUBESOLO_PATH \
        --local-storage=true \
        --debug=false
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
            if curl -sk https://127.0.0.1:6443/version 2>/dev/null | grep -q '"gitVersion"'; then
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

echo "🚀  Installing kubesoloctl ..."
bash install-kubesoloctl.sh

echo "🚀  Installing kubectl ..."
bash install-kubectl.sh $KUBESOLO_PATH

# Exit with success code
exit 0
