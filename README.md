# Alpine Linux bootstrap

This repository contains steps to setup a new Alpine Linux system from scratch in less than 5 minutes.

- Download Alpine Linux Virtual from https://alpinelinux.org/downloads/
- Boot the image, login as root and run `setup-alpine`.
- Reboot.
- Log in as root.
- Fetch `setup.sh`: `wget https://raw.githubusercontent.com/oinuar/alpine-linux-bootstrap/master/setup.sh`.
- Put your SSH `authorized_keys` file somewhere that is accessible via `wget`.
- Execute `/bin/ash setup.sh USERNAME "$(wget -qO- http://secret-place/authorized_keys/for/USERNAME)"`
- Enjoy your new Alpine Linux system.

# What does `setup.sh` do?
- It assumes that you have two network interfaces: eth0 for external network and eth1 for internal network.
- Installs git, build utilities, Docker and Samba.
- Enables PAX softmode.
- Configures Samba to share home directories and /tmp directory.
- Configures sshd to disable password logins.
- Binds sshd and Samba to eth1.
- Creates a non-root unix user and samba user. Unix user is left without password since authorized_keys are initialized that allow you to log in via SSH.
