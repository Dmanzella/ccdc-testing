#!/bin/bash

# Function to download proxy certificate file
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

    case "$DISTRIBUTION" in
        "Ubuntu" | "Debian")
            sudo apt-get update
            sudo apt-get install -y ca-certificates
            sudo cp "$CERTIFICATE_FILE" /usr/local/share/ca-certificates/
            sudo update-ca-certificates
            echo "Acquire::http::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
            echo "Acquire::https::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
            ;;
        "Red Hat" | "CentOS" | "Fedora")
            sudo yum install -y ca-certificates
            sudo cp "$CERTIFICATE_FILE" /etc/pki/ca-trust/source/anchors/
            sudo update-ca-trust
            ;;
        "Alpine")
            apk add --no-cache ca-certificates
            sudo cp "$CERTIFICATE_FILE" /usr/local/share/ca-certificates/
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
