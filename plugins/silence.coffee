module.exports =
    pattern: /!тихо$/
    name: 'Silence'
    isPrivileged: true

    onMsg: (msg) ->
        @bot.setQuietMode(Date.now() + 300000)
