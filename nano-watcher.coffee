path = require 'path'
util = require 'util'
child_process = require 'child_process'
exec = child_process.exec
spawn = child_process.spawn

watch = require 'watch'
fs = require 'fs-extra'
psTree = require 'ps-tree'

packageInfo = require './package.json'

configName = 'nano-watcher.json'
configPath =  null
watchInterval = 200
restartPause = 500
procCwd = null

appArgs = require('minimist')(
    process.argv.slice 2
    alias:
        config: 'c'
        interval: 'i'
        delay: 'd'
        help: 'h'
        cwd: 'w'
        run: 'r'
        version: 'v'
        json: 'j'
        # source: 's'
        # path: 'p'
        # name: 'n'
        # app: 'a'
        # args: 'g'
)

# console.log appArgs

commandsHelp = '\xA0\xA0\xA0\xA0nano-watcher v.' + packageInfo.version + '
\n\n\xA0\xA0\xA0\xA0--config, -c <path>    Load config, where <path> is *.json file of directory with <nano-watcher.json> file
\n\n\xA0\xA0\xA0\xA0--json, -j {...}       Read config from *.json
\n\n\xA0\xA0\xA0\xA0--interval, -i 200     Interval in ms
\n\n\xA0\xA0\xA0\xA0--delay, -d 500        Restart delay in ms
\n\n\xA0\xA0\xA0\xA0--cwd, -w <path>       Working directory
\n\n\xA0\xA0\xA0\xA0--help, -h             Show this help
\n\n\xA0\xA0\xA0\xA0--version, -v          Show version\n'


t = Object.prototype.toString
isString    = (s) ->  t.call(s) is '[object String]'
isArray     = (s) ->  t.call(s) is '[object Array]'
isObject    = (s) ->  t.call(s) is '[object Object]'
isFunction  = (s) ->  t.call(s) is '[object Function]'
isNumber    = (s) ->  s is s and (t.call(s) is '[object Number]')

fileExists = (path) -> # from SO or SU
    try
        return fs.statSync(path).isFile()
    catch e
        if e.code is 'ENOENT' # no such file or directory. File really does not exist
            return false
        else
            throw e # something else went wrong, we don't have rights, ...

dirExists = (path) -> # from SO or SU
    try
        return fs.statSync(path).isDirectory()
    catch e
        if e.code is 'ENOENT' # no such file or directory. File really does not exist
            return false
        else
            throw e # something else went wrong, we don't have rights, ...

`Date.prototype.timeNow = function(){
    return ((this.getHours() < 10)?"0":"")
    + this.getHours() + ":"
    + ((this.getMinutes() < 10)?"0":"")
    + this.getMinutes() + ":"
    + ((this.getSeconds() < 10)?"0":"")
    + this.getSeconds();}`

searchConfig = (cName) ->
    cName = cName or configName
    cwd = process.cwd()
    pathRoot = path.parse( cwd ).root
    dirs = cwd.split( path.sep ).slice 1
    dirs.unshift pathRoot
    dirs.push cName
    userConf = null
    while dirs.length > 1
        cPath = path.join.apply( @, dirs )
        # console.log 'cPath', cPath
        dirs.splice -2, 1
        if fileExists cPath
            userConf = fs.readJsonSync cPath
            console.log 'Config loaded:', cPath
            if isObject userConf
                configPath = cPath
            else
                throw new Error 'Wrong format of config file: ' + cPath

    return userConf

setCwd = (p) ->
    stat = fs.statSync p
    if stat.isFile()
        p = path.dirname p
        stat = fs.statSync p
    if stat.isDirectory()
        procCwd = p
        process.chdir p
    else
        throw new Error "Can't change dir to (not a directory): " + p

loadConf = (cPath) ->
    conf = {
        sources: []
        watchInterval: appArgs.interval or 200
        restartPause: appArgs.delay or 500
    }
    if cPath isnt `undefined`
        cPath = path.resolve path.normalize cPath
        if dirExists cPath
            cPath = path.join cPath, configName
        if fileExists cPath
            userConf = fs.readJsonSync cPath
            console.log 'Config loaded:', cPath
            if isObject userConf
                configPath = cPath
            else
                throw new Error 'Wrong format of config file: ' + cPath
        else
            userConf = searchConfig( cPath ) or {}
    else
        userConf = searchConfig( cPath ) or {}

    for own key, val of userConf
        conf[key] = val

    watchInterval = conf.watchInterval
    restartPause = conf.restartPause
    return conf

# -----------------------------------------------------------------------------
# {
#     "path": "./",
#     "src": "",
#     "dist": "",
#     "ext": ["js"],
#     "command": {
#         "path": "./dev",
#         "name": "build",
#         "app": "node",
#         "args": ["build.js"]
#     }
# }

watchFile = (file, cb) ->
    mtimePrev = fs.statSync( file ).mtime.getTime()
    xt = =>
        try
            stat = fs.statSync file
        catch
            return
        mtime = stat.mtime.getTime()
        if mtime isnt mtimePrev
            cb file
            mtimePrev = mtime
    setInterval xt, watchInterval

class Source

    cmdRun = (cmd, file) ->
        args = []
        for arg in cmd.args
            if isObject arg
                switch arg.data
                    when 'file'
                        args.push file or arg.alt or ''
            else
                args.push arg
        # console.log 'spawn', cmd.app, args, cmd.spawnOpt
        cmd.proc = spawn cmd.app, args, cmd.spawnOpt
        cmd.proc.stdout.on( 'data', (data) ->
            data = data.toString()
            if '\n' is data.slice -6, -5
                data = data.slice(0, -6) + data.slice -5
            if '\n' is data.slice -1
                data = data.slice 0, -1
            if '\n' is data.slice -1
                data = data.slice 0, -1
            console.log '    ', cmd.name, data
        )

        cmd.proc.stderr.on( 'data', (data) ->
            data = data.toString();
            if '\n' is data.slice -6, -5
                data = data.slice(0, -6) + data.slice -5
            if '\n' is data.slice -1
                data = data.slice 0, -1
            if '\n' is data.slice -1
                data = data.slice 0, -1
            console.error '    ', cmd.name, data
        )

        cmd.proc.on 'error', (error) -> console.error  '---- Error in <', cmd.name, '>', error.message
        cmd.proc.on 'exit', -> if cmd.proc isnt null then cmd.proc = null

    run: (file) ->
        if not @command then return

        # console.log ''
        # return

        for cmd in @command
            console.log '[' + new Date().timeNow() + '] [', cmd.name, ']', file or '<no file>'
            if cmd.proc isnt null
                # cmd.proc.on( 'exit',
                #     ->
                #         setTimeout(
                #             ->
                #                 cmdRun cmd, file
                #             500
                #         )
                # )
                # cmd.proc.kill 'SIGTERM'
                # cmd.proc.kill 'SIGKILL'
                # cmd.proc.kill()
                psTree( cmd.proc.pid, (err, children) ->
                    spawn(
                        'kill'
                        ['-9'].concat children.map( (p) -> p.PID )
                    )
                    setTimeout(
                        ->
                            cmdRun cmd, file
                        500
                    )
                )
            else
                cmdRun cmd, file
        return @

    runAll: ->

    watchTree: (dir) ->
        wOpt =
            persistent: true
            interval: watchInterval
            ignoreDotFiles: true
            ignoreUnreadableDir: true
            ignoreNotPermitted: true
            ignoreDirectoryPattern: /node_modules/

        if @ext isnt undefined
            ext = @ext
            wOpt.filter = (file) => -1 isnt ext.indexOf path.extname(file).slice(1)

        xt = (f, curr, prev) =>
            if prev isnt null and curr isnt null and not isObject( f )
                console.log 'f', f
                @run f
            # if isObject( f ) and prev is null and curr is null
                # Finished walking the tree
            # else if prev is null
                # f is a new file
            # else if curr.nlink is 0
                # f was removed
            # else
                # f was changed

        watch.watchTree dir, wOpt, xt
        return @

    stopFile: ->
        if @fileWatchInterval isnt `undefined`
            clearInterval @fileWatchInterval
        return @

    stopTree: ->
        watch.unwatchTree @fullSrcPath
        return @

    stop: ->
        @stopFile().stopTree()
        return @

    watch: ->
        srcPath = fs.statSync @fullSrcPath
        if srcPath.isFile()
            @fileWatchInterval = watchFile @fullSrcPath, (f) => @run f
        else if srcPath.isDirectory()
            @watchTree @fullSrcPath
        else
            throw new Error 'Wrong source.path type (not file or directory): ' + @path
        return @

    constructor: (opt) ->
        if not isObject opt
            throw new Error 'Wrong options format. Expect: "Object" Get: "' + t.call(opt) + '"'
        @path = opt.path or './'
        # @src = opt.src or ''
        # @dist = opt.dist or ''
        @ext = opt.ext or []

        # @fullSrcPath = path.join @path, @src
        # @fullDistPath = path.join @path, @dist

        @fullSrcPath = path.resolve './', @path
        # @fullDistPath = path.normalize @path

        command = opt.command
        if isString command
            @command = [
                {
                    app: command
                    path: command.path or './'
                }
            ]
        else if command isnt `undefined`
            if isObject command
                command = [command]
            if not isArray command
                throw new Error 'source.command is not Object or Array of Objects'
            @command = []
            for cmd in command
                if cmd.app is `undefined`
                    throw new Error 'command.app is undefined'
                if cmd.args
                    cmd.args = if isArray(cmd.args) then cmd.args else [ cmd.args.toString() ]
                c =
                    app: cmd.app
                    name: cmd.name or cmd.app
                    path: cmd.path or @path
                    args: cmd.args or []
                    proc: null
                cwd = path.resolve c.path
                if not dirExists cwd
                    cwd = path.dirname cwd
                c.spawnOpt = cwd: cwd
                @command.push c


runWatcher = (conf) ->
    if conf.sources
        srcs = []
        for src in conf.sources
            s = new Source src
            # console.log 'command', s.command
            srcs.push s
            if appArgs.run is `undefined`
                s.watch()
            else
                s.runAll()
        conf.sources = srcs

nanoWatch = ->

    if appArgs.help isnt `undefined`
        console.log commandsHelp
        return
    if appArgs.version isnt `undefined`
        console.log packageInfo.version
        return
    if appArgs.json isnt `undefined`
        try
            conf = JSON.parse appArgs.json
        catch err
            throw new Error err
        console.log 'parsed conf from json:', conf
    else
        try
            conf = loadConf appArgs.config
        catch err
            throw new Error err

    cwd = appArgs.cwd or configPath
    if cwd
        setCwd cwd

    if configPath isnt null
        watchFile( configPath,
            =>
                try
                    newConf = loadConf configPath
                catch e
                    console.error e
                    throw new Error 'Config load error:'
                for src in conf.sources
                    src.stop()
                conf = newConf
                # runWatcher conf.sources
                runWatcher newConf
        )
    # else
    runWatcher conf

    # console.log conf.sources

module.exports = nanoWatch
