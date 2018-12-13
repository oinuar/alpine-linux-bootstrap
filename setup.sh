#!/bin/ash 

# Print usage if there are not enough arguments.
if [ "$#" -lt 2 ]; then
    echo "Usage $0: [username] [authorized_keys]"
    exit 1
fi

# Revert default config files back.
mv /etc/apk/repositories.default /etc/apk/repositories
mv /etc/ssh/sshd_config.default /etc/ssh/sshd_config
mv /etc/samba/smb.conf.default /etc/samba/smb.conf

# Set to exit on first error.
set -e

# Backup default repository list. 
cat /etc/apk/repositories > /etc/apk/repositories.default

# Enable community main repository.
cat /etc/apk/repositories | grep community | grep -v edge | sed 's/#//' >> /etc/apk/repositories

# Update package list and install system packages.
apk update
apk add git openssh build-base samba curl nano docker

# Enable PAX softmode to make Docker work correctly.
echo "kernel.pax.softmode = 1" > /etc/sysctl.d/01-pax-softmode.conf
sysctl -p /etc/sysctl.d/01-pax-softmode.conf

# Make a backup of default smb.conf.
mv /etc/samba/smb.conf /etc/samba/smb.conf.default

# Overwrite smb.conf to bind only internal network eth1 and lo.
echo "# Created by setup.sh
[global]
        bind interfaces only = Yes
        dns proxy = No
        interfaces = lo eth1
        log file = /usr/local/samba/var/log.%m
        map to guest = Bad User
        max log size = 50
        server role = standalone server
        server string = Development Server
        workgroup = MYGROUP
        idmap config * : backend = tdb

[homes]
        browseable = No
        comment = Home Directories
        read only = No

[tmp]
        comment = Temporary file space
        guest ok = Yes
        path = /tmp
        read only = No" > /etc/samba/smb.conf

# Make a backup of default sshd_config.
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.default

# Overwrite sshd_config to listen only internal network eth1.
echo "# Created by setup.sh
ListenAddress           $(ifconfig eth1 | grep 'inet addr' | cut -d: -f2 | cut -d ' ' -f1)
AuthorizedKeysFile      .ssh/authorized_keys
PasswordAuthentication  no
Subsystem               sftp    /usr/lib/ssh/sftp-server" > /etc/ssh/sshd_config

# Change motd.
echo "Welcome to Alpine!

The Alpine Wiki contains a large amount of how-to guides and general
information about administrating Alpine systems.
See <http://wiki.alpinelinux.org>.
" > /etc/motd

# Start samba and docker at default runlevel.
rc-update add docker default
rc-update add samba default

# Start services.
/etc/init.d/sshd restart
/etc/init.d/docker start
/etc/init.d/samba start

# Add normal unix user.
adduser -h /home/user -s /bin/ash -D $1

# Add user to docker group.
addgroup $1 docker

# Initialize ssh access for user.
su $1 -s /bin/ash -c "cd ~ && mkdir .ssh && echo '$2' > .ssh/authorized_keys && chmod 700 .ssh && chmod 600 .ssh/authorized_keys"

# Unlock user.
passwd -u $1

# Add samba user.
smbpasswd -a $1
