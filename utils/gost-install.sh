#!/bin/bash

# Check Root User

# If you want to run as another user, please modify $EUID to be owned by this user
if [[ "$EUID" -ne '0' ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi

# Set the desired GitHub repository
repo="go-gost/gost"
base_url="https://api.github.com/repos/$repo/releases"

# Function to download and install gost
install_gost() {
    version=$1
    # Detect the operating system
    if [[ "$(uname)" == "Linux" ]]; then
        os="linux"
    elif [[ "$(uname)" == "Darwin" ]]; then
        os="darwin"
    elif [[ "$(uname)" == "MINGW"* ]]; then
        os="windows"
    else
        echo "Unsupported operating system."
        exit 1
    fi

    # Detect the CPU architecture
    arch=$(uname -m)
    case $arch in
    x86_64)
        cpu_arch="amd64"
        ;;
    armv5*)
        cpu_arch="armv5"
        ;;
    armv6*)
        cpu_arch="armv6"
        ;;
    armv7*)
        cpu_arch="armv7"
        ;;
    aarch64)
        cpu_arch="arm64"
        ;;
    i686)
        cpu_arch="386"
        ;;
    mips64*)
        cpu_arch="mips64"
        ;;
    mips*)
        cpu_arch="mips"
        ;;
    mipsel*)
        cpu_arch="mipsle"
        ;;
    *)
        echo "Unsupported CPU architecture." >&2
        exit 1
        ;;
    esac
    get_download_url="$base_url/tags/$version"
    download_url=$(curl -s "$get_download_url" | grep -Eo "\"browser_download_url\": \".*${os}.*${cpu_arch}.*\"" | awk -F'["]' '{print $4}' | head -n1)

    # Download the binary
    echo "Downloading gost version $version... (by $download_url)"
    curl -fsSL -o gost.tar.gz "$download_url" || ( echo "gost download by $download_url failed" >&2 ; exit 1 ; )

    # Extract and install the binary
    echo "Installing gost..."
    tar -xzf gost.tar.gz || ( echo "gost unarchive failed by $download_url" >&2 ; exit 1 ; )
    chmod +x gost
    mv gost /usr/local/bin/gost || ( echo "gost not found after install" >&2 ; exit 1 ; )

    echo "gost installation completed!"
}

# Retrieve available versions from GitHub API
curl -s "$base_url" >/tmp/gost-versions.out 2>/tmp/gost-versions.err || (
  echo "can't get available gost versions:" >&2 ;
  cat /tmp/gost-versions.err >&2 ;
  exit 1 ;
)

versions=$(curl -s "$base_url" 2>/dev/null | grep -oP 'tag_name": "\K[^"]+')

if [[ "$versions" == "" ]]; then
  echo "Can't get versions by url: $base_url" >&2
  exit 1
fi

# Check if --install option provided
if [[ "$1" == "--install" ]]; then
    # Install the latest version automatically
    latest_version=$(echo "$versions" | head -n 1)
    install_gost $latest_version
else
    # Display available versions to the user
    echo "Available gost versions:"
    select version in $versions; do
        if [[ -n $version ]]; then
            install_gost $version
            break
        else
            echo "Invalid choice! Please select a valid option."
        fi
    done
fi
