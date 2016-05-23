# nano-watcher
Small and fast watch for files and directory changes and commands execution

Run watcher:

    nano-watcher -c path/to/config.json
    nano-watcher --config path/to/config.json
    nano-watcher -c path/to/directory/with/nano-watcher.json/

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
