config = require '../lib/config'

module.exports =
    pattern: /!тихо$/
    name: 'Silence'
    isPrivileged: true

    init: ->
        @sudoList = config.toIdList(config.options.quotes_sudo)    

    onMsg: (msg) ->
        @bot.setQuietMode(Date.now() + 300000)

    isSudo: (msg) ->
        @bot.isSudo(msg) or msg.from.id in @sudoList        
