#!/bin/bash

# NOTES #
# This script will not work for browsers such as firefox, they will need to be configured manually"

# download proxy certificate file
download_certificate() {
    local PATCH_URL="$1"
    local CERTIFICATE_FILE="certificate.crt"
    curl -o "$CERTIFICATE_FILE" "$PATCH_URL"
    return $?
}

# Function to configure proxy and certificate based on Linux distribution
configure_proxy_certificate() {
    local DISTRIBUTION="$1"
    local CERTIFICATE_FILE="certificate.crt"
    local PROXY="10.120.0.200:8080"  # Update with your proxy settings
    local CERT_DIR="/usr/local/share/ca-certificates/extra"

    case "$DISTRIBUTION" in
        "Ubuntu" | "Debian")
        # Ubuntu must use .crt format
            if [ ! -d "$CERT_DIR" ]; then
                sudo mkdir -p "$CERT_DIR"
            fi
            sudo apt update
            sudo apt  install -y ca-certificates
            sudo cp "$CERTIFICATE_FILE" "$CERT_DIR"
            sudo update-ca-certificates
            echo "Acquire::http::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
            echo "Acquire::https::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
            ;;
        "Red Hat" | "CentOS" | "Fedora")
            if [ ! -d "$CERT_DIR" ]; then
                sudo mkdir -p "$CERT_DIR"
            fi
            sudo yum install -y ca-certificates
            sudo cp "$CERTIFICATE_FILE" "$CERT_DIR"
            sudo update-ca-trust
            ;;
        "Alpine")
            if [ ! -d "$CERT_DIR" ]; then
                sudo mkdir -p "$CERT_DIR"
            fi
            apk add --no-cache ca-certificates
            sudo cp "$CERTIFICATE_FILE" "$CERT_DIR"
            sudo update-ca-certificates
            ;;
        *)
            echo "Unsupported distribution: $DISTRIBUTION"
            return 1
            ;;
    esac

    # Configure proxy
    echo "export http_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
    echo "export https_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
}

# Main function
main() {
    local PATCH_URL="$1"
    local DISTRIBUTION="Unknown"

    # Determine Linux distribution
    if command -v apt-get >/dev/null ; then
        DISTRIBUTION=$(grep -oP '(?<=^ID=)\w+' /etc/os-release)
    elif command -v yum >/dev/null ; then
        DISTRIBUTION="Red Hat"
    elif command -v apk >/dev/null ; then
        DISTRIBUTION="Alpine"
    else
        echo "Unsupported distribution"
        exit 1
    fi

    # Download certificate and configure proxy/certificate
    download_certificate "$PATCH_URL" && configure_proxy_certificate "$DISTRIBUTION"
    return $?
}

# Check if the script is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Execute main function if the script is not sourced
    main "$@"
fi
