msgCache = require '../lib/msg_cache'

module.exports =
    name: 'Username'
    pattern: /!username (\d+)/
    isPrivileged: true
    warnPrivileged: false

    onMsg: (msg) ->
        id = Number msg.match[1]
        usr = msgCache.getUserById id
        if usr?
            msg.reply '@' + usr.username
        else
            msg.reply 'Не найдено'


