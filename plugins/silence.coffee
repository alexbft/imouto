config = require '../lib/config'

module.exports =
    pattern: /!!?тихо$/
    name: 'Silence'
    isPrivileged: true

    init: ->
        @sudoList = config.toIdList(config.options.quotes_sudo)    

    onMsg: (msg) ->
        if msg.text == '!!тихо'
          dur = 1800000
        else
          dur = 300000
        @bot.setQuietMode(Date.now() + dur)

    isSudo: (msg) ->
        @bot.isSudo(msg) or msg.from.id in @sudoList        
