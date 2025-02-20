By sysfredintech

February 20, 2025

## Backup script using rsync.
Remote directory to local directory - local directory to remote directory - local directory to local directory.
Check available disk space before backup.
Check the number of modified items before backup, maximum value configurable as a percentage.
Send an email in case of failure.

Requires a configuration file "autosyncro.conf" in the script's current directory
Edit the configuration file "autosyncro.conf" to customize your backup

## Dependencies on the local machine

- rsync (essential for backup)
- ssh-agent pre-configured (optional) for key and passphrase management if remote directory is defined
(https://wiki.archlinux.org/title/SSH_keys)
- swaks (optional) for sending emails in case of failure

## Dependencies on the remote server

- rsync (essential for backup)
