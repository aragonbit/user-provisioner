#!/bin/bash

set -e

# Prompt and validate username
read_username() {
    while true; do
        read -rp "Enter the username (lowercase letters, digits, '-', '_'): " USERNAME
        if [[ "$USERNAME" =~ ^[a-z0-9_-]+$ ]]; then
            break
        else
            echo "Invalid username. Only lowercase letters, digits, hyphens and underscores allowed."
        fi
    done
}

# Prompt for sudo privileges
read_sudo_choice() {
    while true; do
        read -rp "Grant sudo privileges without password? (y/n): " yn
        case $yn in
            [Yy]*) SUDO_NOPASSWD="yes"; break ;;
            [Nn]*) SUDO_NOPASSWD="no"; break ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Prompt whether to add a public key
read_ssh_key_choice() {
    while true; do
        read -rp "Add a public SSH key for the user? (y/n): " yn
        case $yn in
            [Yy]*) ADD_KEY="yes"; break ;;
            [Nn]*) ADD_KEY="no"; break ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Prompt for public key input
read_ssh_key() {
    echo "Paste the public SSH key (single line), then press ENTER:"
    read -r PUB_KEY
    if [[ -z "$PUB_KEY" ]]; then
        echo "No public key entered, skipping."
        ADD_KEY="no"
    fi
}

create_user() {
    if id -u "$USERNAME" >/dev/null 2>&1; then
        echo "User '$USERNAME' already exists."
    else
        sudo useradd -m -s /bin/bash "$USERNAME"
        echo "User '$USERNAME' created."
    fi
}

configure_sudo() {
    SUDO_FILE="/etc/sudoers.d/99-$USERNAME"
    if [[ "$SUDO_NOPASSWD" == "yes" ]]; then
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "$SUDO_FILE" >/dev/null
        sudo chmod 440 "$SUDO_FILE"
        echo "Sudo privileges without password granted."
    else
        if [[ -f "$SUDO_FILE" ]]; then
            sudo rm "$SUDO_FILE"
            echo "Sudo privileges removed."
        fi
        echo "User will need password for sudo."
    fi
}

add_ssh_key() {
    if [[ "$ADD_KEY" == "yes" ]]; then
        sudo mkdir -p /home/"$USERNAME"/.ssh
        echo "$PUB_KEY" | sudo tee /home/"$USERNAME"/.ssh/authorized_keys >/dev/null
        sudo chmod 700 /home/"$USERNAME"/.ssh
        sudo chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
        sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
        echo "Public SSH key added."
    fi
}

main() {
    echo "=== User Creation Script ==="
    read_username
    read_sudo_choice
    read_ssh_key_choice
    if [[ "$ADD_KEY" == "yes" ]]; then
        read_ssh_key
    fi

    create_user
    configure_sudo
    add_ssh_key

    echo "User '$USERNAME' setup completed."
    if [[ "$SUDO_NOPASSWD" == "yes" ]]; then
        echo "- sudo without password enabled"
    else
        echo "- sudo requires password"
    fi
    if [[ "$ADD_KEY" == "yes" ]]; then
        echo "- public SSH key installed"
    else
        echo "- no SSH key installed"
    fi
}

main
