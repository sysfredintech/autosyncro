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
93620c523d41675a14cebbae4ce7d38ae09d6145ed7e27315d54f50a095f3584
