#!/bin/bash

# Template credit to CPP

# PATCH_URL will need to be changed once correct path is known during comp
PATCH_URL=http://10.120.0.9/Proxy_Certificates/certificate.crt
PROXY=10.120.0.200:8080                # This is what regionals was

RHEL(){
    sudo yum install -y ca-certificates
    # Install certificate
    curl -o cert.crt "$PATCH_URL"
    sudo cp cert.crt /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust

    # Configure proxy
    echo "export http_proxy=\"$PROXY\"" >> ~/.bashrc
    echo "export https_proxy=\"$PROXY\"" >> ~/.bashrc
    source ~/.bashrc
}

DEBIAN(){
    # download and install certificate
    sudo apt-get install -y ca-certificates
    curl -o cert.crt "$PATCH_URL"
    sudo cp cert.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates

    #configure proxy
    export http_proxy=\"$PROXY\"
    export https_proxy=\"$PROXY\"
    echo "export http_proxy=\"$PROXY\"" >> ~/.bashrc
    echo "export https_proxy=\"$PROXY\"" >> ~/.bashrc
    source ~/.bashrc

    #configure for apt
    echo "Acquire::http::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
    echo "Acquire::https::Proxy \"$PROXY\";" | sudo tee -a /etc/apt/apt.conf >/dev/null
}

UBUNTU(){
    DEBIAN
}

ALPINE(){
    apk add --no-cache ca-certificates

    # Install certificate
    curl -o cert.crt "$PATCH_URL"
    sudo cp cert.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates

    # Configure proxy
    echo "export http_proxy=\"$PROXY\"" >> /etc/profile
    echo "export https_proxy=\"$PROXY\"" >> /etc/profile
    source /etc/profile
}

SLACK(){
    echo "its fucked I dont even know what slack is"
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





