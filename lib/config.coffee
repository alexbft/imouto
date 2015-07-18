fs = require 'fs'
logger = require 'winston'

configFileName = __dirname + '/../config/main.config'
exports.options = options = {}

split2 = (line, c) ->
    ii = line.indexOf(c)
    if ii == -1
        []
    else
        [line.substr(0, ii), line.substr(ii + c.length)]

readConfig = (fileName) ->
    configText = fs.readFileSync(fileName, encoding: 'utf8')
    buf = {}
    for line, i in configText.split('\n')
        line = line.trim()
        if line == '' or line.startsWith('#')
            continue
        [key, v] = split2(line, '=')
        if not key?
            logger.error("Config: Error in line #{i + 1}")
            return
        key = key.trim()
        v = v.trim()
        buf[key] = v
    for key, v of buf
        options[key] = v

toIdList = exports.toIdList = (s) ->
    if not s? or s.trim() == ''
        return []
    (parseInt(id.trim(), 10) for id in s.split(','))

if fs.existsSync configFileName
    readConfig configFileName

exports.sudoList = toIdList(options.sudo)
exports.bannedIds = toIdList(options.banned)

exports.setUserInfo = (info) ->
    logger.info "Our id is: #{info.id}"
    exports.userId = info.id
    exports.userName = info.username
