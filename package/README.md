Package for Debian and Debian based

AutoSyncro v1.0

Dependencies:    - bash
                - rsync
Optional dependencies:   - swaks
                            - cron

Rsync is required on remote server if backup is done via ssh

Content of package autosyncro.deb
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
b79bec3702ff6c15a1e0130b0593ec0544667f1fc2d85a41ce23693d0cfa9a3f