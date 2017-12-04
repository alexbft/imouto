logger = require 'winston'
config = require '../lib/config'
misc = require '../lib/misc'

search = (txt, rsz = 1) ->
    misc.get "https://www.googleapis.com/customsearch/v1?",
        qs:
            key: config.options.googlekey
            cx: config.options.googlecx
            gl: 'ru'
            hl: 'ru'
            num: rsz
            safe: 'off'
            q: txt
        json: true
    .then (res) ->
        #logger.debug JSON.stringify res
        res.items

module.exports =
    name: 'Google'
    pattern: /!(поиск|ищи|найди|гугл|g|поищи|найти|gg)(?: ([^]+))?/

    onMsg: (msg, safe) ->
        cmd = msg.match[1]
        txt = msg.match[2]
        reply_to_id = msg.message_id
        if not txt? and msg.reply_to_message?.text?
            txt = msg.reply_to_message.text
            reply_to_id = msg.reply_to_message.message_id
        if not txt?
            return
        safe search txt
        .then (results) ->
            if not results? or results.length == 0
                msg.send 'Ничего не найдено!', reply: reply_to_id
            else
                result = results[0]
                url = result.link
                if cmd == 'gg'
                    answer = "#{result.titleNoFormatting}\n#{url}"
                else
                    answer = url
                msg.send answer, reply: reply_to_id

    onError: (msg) ->
        msg.send 'Поиск не удался...'