misc = require '../lib/misc'

module.exports =
    name: 'Google'
    pattern: /!(поиск|ищи|найди|гугл|g|поищи|найти|gg) ([^]+)/

    onMsg: (msg, safe) ->
        cmd = msg.match[1]
        txt = msg.match[2]
        safe misc.google txt
        .then (results) ->
            if results.length == 0
                msg.reply('Ничего не найдено!')
            else
                result = results[0]
                url = result.unescapedUrl
                if cmd == 'gg'
                    answer = "#{result.titleNoFormatting}\n#{url}"
                else
                    answer = url
                msg.send answer

    onError: (msg) ->
        msg.send 'Поиск не удался...'