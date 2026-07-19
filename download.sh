#!/bin/bash

TARGET_DIR="${1:-./kubesolo}"
mkdir -p $TARGET_DIR || { echo "❌  Error: Failed to create directory $TARGET_DIR"; exit 1; }
pushd $TARGET_DIR || { echo "❌  Error: Failed to enter directory $TARGET_DIR"; exit 1; }

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

KUBESOLO_INSTALL_URL_SRC="https://get.kubesolo.io"
KUBESOLO_INSTALL_URL_NEW="$(curl -sLw '%{url_effective}' -o /dev/null $KUBESOLO_INSTALL_URL_SRC)"
KUBESOLO_UNINSTALL_URL_NEW="$(curl -sLw '%{url_effective}' -o /dev/null https://uninstall.kubesolo.io)"

echo "📥  Downloading KubeSolo package to $TARGET_DIR ..."
KUBESOLO_INSTALL_URL=$(convert_github_url "$KUBESOLO_INSTALL_URL_NEW")
if [[ "$__KSPEEDER_AVAILABLE__" == "true" ]]; then
    curl -sfL "$KUBESOLO_INSTALL_URL" \
        | sed "s|$KUBESOLO_INSTALL_URL_SRC|$KUBESOLO_INSTALL_URL|g" \
        | sed "s|https://github.com|https://gh.linkease.net:5443|g" \
        | KUBESOLO_OFFLINE=true bash -s -- --download-only
else
    curl -sfL "$KUBESOLO_INSTALL_URL" \
        | sed "s|$KUBESOLO_INSTALL_URL_SRC|$KUBESOLO_INSTALL_URL|g" \
        | KUBESOLO_OFFLINE=true bash -s -- --download-only
fi
echo "🔍  Validating KubeSolo package ..."
for file in kubesolo-*-offline.tar.gz; do
    [ -e "$file" ] || continue

    echo "📦  Package file: $file"

    if gzip -t "$file" 2>/dev/null; then
        echo "    ✅  gzip integrity check passed"
    else
        echo "    ❌  gzip integrity check failed"
        exit 1
    fi

    if tar -tzf "$file" > /dev/null 2>&1; then
        echo "    ✅  tarball structure check passed"
    else
        echo "    ❌  tarball structure check failed"
        exit 1
    fi

    echo "    📄  Entries: $(tar -tzf "$file" 2>/dev/null | wc -l)"
    echo "    📏  Size: $(ls -lh "$file" | awk '{print $5}')"
    echo "✅  Package $file is valid and intact"
done
echo "✅  KubeSolo package successfully downloaded to $TARGET_DIR!"

echo "📥  Downloading KubeSolo uninstall to $TARGET_DIR ..."
wget "$(convert_github_url "$KUBESOLO_UNINSTALL_URL_NEW")" -O uninstall.sh && chmod +x uninstall.sh \
    || { echo "❌  Error: Failed to download KubeSolo uninstall"; exit 1; }
echo "✅  KubeSolo uninstall successfully downloaded to $TARGET_DIR!"

echo "📥  Downloading setup to $TARGET_DIR ..."
wget "$(convert_github_url "https://raw.githubusercontent.com/bootsmoker/kubesolo/HEAD/setup.sh")" -O setup.sh && chmod +x setup.sh \
    || { echo "❌  Error: Failed to download setup"; exit 1; }
echo "✅  Setup successfully downloaded to $TARGET_DIR!"

echo "📥  Downloading kubectl install to $TARGET_DIR ..."
wget "$(convert_github_url "https://raw.githubusercontent.com/bootsmoker/kubesolo/HEAD/install-kubectl.sh")" -O install-kubectl.sh && chmod +x install-kubectl.sh \
    || { echo "❌  Error: Failed to download kubectl install"; exit 1; }
echo "✅  Kubectl install successfully downloaded to $TARGET_DIR!"

echo "📥  Downloading kubectl uninstall to $TARGET_DIR ..."
wget "$(convert_github_url "https://raw.githubusercontent.com/bootsmoker/kubesolo/HEAD/uninstall-kubectl.sh")" -O uninstall-kubectl.sh && chmod +x uninstall-kubectl.sh \
    || { echo "❌  Error: Failed to download kubectl uninstall"; exit 1; }
echo "✅  Kubectl uninstall successfully downloaded to $TARGET_DIR!"

echo "📥  Downloading kubesoloctl install to $TARGET_DIR ..."
wget "$(convert_github_url "https://raw.githubusercontent.com/bootsmoker/kubesolo/HEAD/install-kubesoloctl.sh")" -O install-kubesoloctl.sh && chmod +x install-kubesoloctl.sh \
    || { echo "❌  Error: Failed to download kubesoloctl install"; exit 1; }
echo "✅  KubeSoloCtl install successfully downloaded to $TARGET_DIR!"

echo "📥  Downloading kubesoloctl uninstall to $TARGET_DIR ..."
wget "$(convert_github_url "https://raw.githubusercontent.com/bootsmoker/kubesolo/HEAD/uninstall-kubesoloctl.sh")" -O uninstall-kubesoloctl.sh && chmod +x uninstall-kubesoloctl.sh \
    || { echo "❌  Error: Failed to download kubesoloctl uninstall"; exit 1; }
echo "✅  KubeSoloCtl uninstall successfully downloaded to $TARGET_DIR!"

popd
exit 0
