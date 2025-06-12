# user-provisioner

**user-provisioner** is a secure and interactive Bash script for provisioning Linux system users with fine-grained access control.

It allows system administrators to create users with:

- Optional `sudo` privileges
- SSH access restricted to one or multiple specific IP addresses
- Configurable login rules using `/etc/security/access.conf`

The tool is ideal for environments where users should only be allowed to connect from known IPs (e.g., backup servers, management nodes, or VPN clients), and where tighter login controls are required without relying solely on firewall rules.

## Features

- Interactive prompts for:
  - Username
  - Number of allowed IPs (or none)
  - Each allowed IP address
  - Whether to assign `sudo` privileges
- Automatically applies SSH login restrictions using PAM (`access.conf`)
- Sudo configuration via `/etc/sudoers.d/` with safe permissions
- Password setup for the new user
- Clear and structured output

## Requirements

- Linux system (Debian/Ubuntu tested)
- Root or `sudo` privileges
- PAM enabled (default on most systems)

## Usage

```bash
chmod +x setup_user.sh
sudo ./setup_user.sh
```
The Script was created with the help of AI
