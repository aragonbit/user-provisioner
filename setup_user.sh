#!/bin/bash

set -e

# Function to prompt and validate the username input
read_username() {
    while true; do
        read -rp "Please enter the username (allowed: lowercase letters, digits, '-', '_'): " USERNAME
        if [[ "$USERNAME" =~ ^[a-z0-9_-]+$ ]]; then
            break
        else
            echo "Invalid username. Only lowercase letters, digits, hyphens and underscores are allowed."
        fi
    done
}

# Function to prompt for the number of allowed IP addresses
read_number_of_ips() {
    while true; do
        read -rp "How many IP addresses should be allowed for SSH access? (Enter 0 for no access): " IP_COUNT
        if [[ "$IP_COUNT" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Please enter a valid non-negative integer."
        fi
    done
}

# Function to collect allowed IP addresses from the user
read_ips() {
    ALLOWED_IPS=()
    for ((i=1; i<=IP_COUNT; i++)); do
        while true; do
            read -rp "Enter allowed IP address #$i: " ip
            # Basic IPv4 format validation
            if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                ALLOWED_IPS+=("$ip")
                break
            else
                echo "Invalid IP format. Please enter a valid IPv4 address."
            fi
        done
    done
}

# Function to ask whether to grant sudo privileges
read_sudo_choice() {
    while true; do
        read -rp "Should the user be granted sudo privileges? (y/n): " yn
        case $yn in
            [Yy]* ) SUDO="yes"; break;;
            [Nn]* ) SUDO="no"; break;;
            * ) echo "Please answer with 'y' or 'n'.";;
        esac
    done
}

# Function to create the user if it does not exist, and set the password
create_user() {
    if id -u "$USERNAME" >/dev/null 2>&1; then
        echo "User '$USERNAME' already exists."
    else
        sudo useradd -m "$USERNAME"
        echo "User '$USERNAME' has been created."
    fi

    sudo passwd "$USERNAME"
}

# Function to configure /etc/security/access.conf to restrict SSH login by IP
configure_access_conf() {
    ACCESS_CONF="/etc/security/access.conf"
    # Remove existing access control lines for this user
    sudo sed -i "/^-:$USERNAME:/d" "$ACCESS_CONF"

    if [[ "$IP_COUNT" -eq 0 ]]; then
        # Deny all access if no IPs are allowed
        echo "-:$USERNAME:ALL" | sudo tee -a "$ACCESS_CONF" >/dev/null
    else
        # Allow access only from specified IPs, deny elsewhere
        IPS_JOINED="${ALLOWED_IPS[*]}"
        echo "-:$USERNAME:ALL EXCEPT $IPS_JOINED" | sudo tee -a "$ACCESS_CONF" >/dev/null
    fi
    echo "Access restrictions for user '$USERNAME' have been updated in $ACCESS_CONF."
}

# Function to manage sudo privileges for the user
configure_sudo() {
    SUDO_FILE="/etc/sudoers.d/99-$USERNAME"
    if [[ "$SUDO" == "yes" ]]; then
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDO_FILE" >/dev/null
        sudo chmod 440 "$SUDO_FILE"
        echo "Sudo privileges have been granted to '$USERNAME'."
    else
        if [[ -f "$SUDO_FILE" ]]; then
            sudo rm "$SUDO_FILE"
            echo "Any existing sudo privileges for '$USERNAME' have been removed."
        fi
    fi
}

# Main script execution
main() {
    echo "== User Setup Script: SSH IP Restrictions and sudo Privileges =="

    read_username
    read_number_of_ips

    if [[ "$IP_COUNT" -gt 0 ]]; then
        read_ips
    fi

    read_sudo_choice

    create_user
    configure_access_conf
    configure_sudo

    echo
    echo "User '$USERNAME' has been configured successfully."
    if [[ "$IP_COUNT" -gt 0 ]]; then
        echo "SSH access restricted to the following IP address(es): ${ALLOWED_IPS[*]}"
    else
        echo "SSH access has been completely restricted for this user."
    fi
    if [[ "$SUDO" == "yes" ]]; then
        echo "Sudo privileges are enabled."
    else
        echo "Sudo privileges are not enabled."
    fi
    echo "Setup process is complete."
}

main
