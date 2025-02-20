# AutoSyncro v1.0

## Package for Debian and Debian-based systems

### Dependencies
- **Required:**
  - `bash`
  - `rsync`
- **Optional:**
  - `swaks` (for email notifications)
  - `cron` (for task scheduling)

### Notes
- **Rsync** is required on the remote server if the backup is performed via SSH.

---

## Package Contents (`autosyncro.deb`)

The package structure is as follows:

.
├── autosyncro
│   ├── DEBIAN
│   │   ├── control
│   │   └── postinst
│   ├── etc
│   │   └── autosyncro
│   │       └── autosyncro.conf
│   └── usr
│       ├── bin
│       │   └── autosyncro
│       └── share
│           └── autosyncro
│               └── README.md
└── autosyncro.deb

sha256sum:
93620c523d41675a14cebbae4ce7d38ae09d6145ed7e27315d54f50a095f3584

---

### Usage
1. Install the package using `dpkg`:
   ```bash
   sudo dpkg -i autosyncro.deb
