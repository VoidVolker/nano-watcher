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

    npm i nano-watcher --save

Run watcher:

    ./node_modules/nano-watcher/bin/nano-watcher -c path/to/config.json


VirtualBox / mounted FS install:

    npm i nano-watcher --save --no-bin-links

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
                    "name": "dist build -- ",
                    "app": "node",
                    "args": ["build.js"]
                }
            }{
                "path": "./client/app",
                "ext": ["coffee"],
                "command": {
                    "name": "coffee client -- ",
                    "app": "coffee",
                    "args": [ "-m", "-b", "-c", {"data": "file"} ]
                }
            }, {
                "path": "./server",
                "ext": ["js"],
                "command": {
                    "name": "WS server -- ",
                    "app": "node-debug",
                    "args": ["--no-preload", "--cli", "server.js"]
                }
            }
        ]
    }

`interval` - interval beetween checks of files change time

`delay` - delay before commands run

`cwd` - working directory, by default - same as config

This module was developed to be powerfull and small tool to run commands on files changes. Works in Virtual box and with mounted FS.

CLI commads:

`--help`, `-h` — show help

`--interval`, `-i` — interval in ms

`--delay`, `-d` — restart delay in ms

`--cwd`, `-w` — working directory

