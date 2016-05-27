[![Join the chat at https://gitter.im/VoidVolker/nano-watcher](https://badges.gitter.im/VoidVolker/nano-watcher.svg)](https://gitter.im/VoidVolker/nano-watcher?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# nano-watcher

Small and fast watch for files and directory changes and commands execution

Global install:

    npm i -g nano-watcher

Run watcher:

    nano-watcher

In this case nano-watcher will search config file `nano-watcher.json` in all directories from current and up.

    nano-watcher -c ./path/to/config.json
    nano-watcher --config /path/to/config.json
    nano-watcher -c path/to/directory/with/nano-watcher.json/

Local install:

    npm i nano-watcher
    npm i nano-watcher --save

Run watcher:

    ./node_modules/nano-watcher/bin/nano-watcher -c path/to/config.json


VirtualBox share / mounted FS install:

    npm i nano-watcher --no-bin-links
    npm i nano-watcher --save --no-bin-links

When running nano-watcher is watching and config file for changes and automatically reload it, so you don't need to restart nano-watcher for config reload.

Config example:

    {
        "interval": 200,
        "delay": "500",
        "cwd": "directory/to/run/"
        "sources": [
            {
                "path": "../index.js",
                "command": {
                    "path": "./",
                    "name": "dist build",
                    "app": "node",
                    "args": ["build.js"]
                }
            }{
                "path": "./client/app",
                "ext": ["coffee"],
                "command": {
                    "name": "coffee client",
                    "app": "coffee",
                    "args": [ "-m", "-b", "-c", {"data": "file"} ]
                }
            }, {
                "path": "./server",
                "ext": ["js"],
                "command": {
                    "name": "WS server",
                    "app": "node-debug",
                    "args": ["--no-preload", "--cli", "server.js"]
                }
            }
        ]
    }

`interval` - interval beetween checks of files change time

`delay` - delay before commands run

`cwd` - working directory, by default - same as config

`command` - can be object or array of objects (several commands)

This module was developed to be powerfull and small tool to run commands on files changes. Works in Virtual box and with mounted FS.



CLI commads:

`--config`, `-c <path>`    Load config, where <path> is *.json file of directory with <nano-watcher.json> file

`--interval`, `-i 200`     Interval in ms

`--delay`, `-d 500`        Restart delay in ms

`--cwd`, `-w <path>`       Working directory

`--help`, `-h`             Show this help

`--version`, `-v`          Show version
