#!/bin/bash

# Template credit to CPP

#######################################################################
# crt format is required for ubuntu #
#######################################################################

# Prompt the user for the URL of the certificate file
read -p "Enter the URL of the certificate file to download: (e.g., http://1.1.1.1/certificate.crt)" PATCH_URL

# Prompt the user for the IP and port of the proxy
read -p "Enter the IP and port of the proxy (e.g., 10.120.0.200:8080): " PROXY

RHEL(){
    sudo yum install -y ca-certificates
    # Install certificate
    curl -o cert.crt --proxy "http://$PROXY" "$PATCH_URL"
    sudo cp cert.crt /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust

    # configure for yum
    echo "proxy=http://$PROXY" | sudo tee -a /etc/yum.conf >/dev/null
    echo "proxy=https://$PROXY" | sudo tee -a /etc/yum.conf >/dev/null

    echo "export http_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
    echo "export https_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
}

DEBIAN(){
    # download and install certificate
    sudo apt-get install -y ca-certificates
    sudo apt-get install -y curl
    curl -o cert.crt --proxy "http://$PROXY" "$PATCH_URL"
    sudo cp cert.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates

    #configure for apt
    echo "Acquire::http::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
    echo "Acquire::https::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null

    #configure for environment
    echo "export http_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
    echo "export https_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
}

UBUNTU(){
    DEBIAN
}

ALPINE(){
    apk add --no-cache ca-certificates

    # Install certificate
    curl -o cert.pem --proxy "http://$PROXY" "$PATCH_URL"
    sudo cp cert.pem /usr/local/share/ca-certificates/
    sudo update-ca-certificates

    # Configure proxy
    echo "http://$PROXY/alpine/latest/main" | sudo tee -a /etc/apk/repositories >/dev/null
    echo "https://$PROXY/alpine/latest/main" | sudo tee -a /etc/apk/repositories >/dev/null
    echo "http://$PROXY/alpine/latest/community" | sudo tee -a /etc/apk/repositories >/dev/null
    echo "https://$PROXY/alpine/latest/community" | sudo tee -a /etc/apk/repositories >/dev/null

    #configure for environment
    echo "export http_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
    echo "export https_proxy=\"$PROXY\"" | sudo tee -a /etc/environment >/dev/null
}

SLACK(){
    echo "good luck soldier"
}

if command -v yum >/dev/null ; then
    RHEL
elif command -v apt-get >/dev/null ; then
    if $(cat /etc/os-release | grep -qi Ubuntu); then
        UBUNTU
    else
        DEBIAN
    fi
elif command -v apk >/dev/null ; then
    ALPINE
elif command -v slapt-get >/dev/null || (cat /etc/os-release | grep -i slackware) ; then
    SLACK
fi
