By sysfredintech

February 22, 2025

## Backup script using rsync and ssh
- Remote directory to local directory
- local directory to remote directory
- local directory to local directory.


## This script checks the number of modified items before backup
## You define the maximum value of items as a percentage
## It sends an email in case of failure if configured


`This script requires configuration file "autosyncro.conf" in the script's current directory`


## Dependencies on the local machine

- rsync (essential for backup)
- ssh-client and ssh-agent pre-configured (optional) for key and passphrase management if remote directory is defined
(https://wiki.archlinux.org/title/SSH_keys)
- swaks (optional) for sending emails in case of failure

## Dependencies on the remote server

- rsync (essential for backup)
- ssh-server

## How to use

- Download `autosyncro.sh` and `autosyncro.conf` in the same directory
- Edit the configuration file `autosyncro.conf` to customize your backup
- Run `chmod +x autosyncro.sh`
- Edit your crontab to schudle your backup `crontab -e`
