logger = require 'winston'
config = require '../lib/config'
misc = require '../lib/misc'

keys = {}

search = (txt, rsz = 1) ->
    misc.get "https://www.googleapis.com/customsearch/v1?",
        qs:
            key: config.options.googlekey
            cx: config.options.googlecx
            gl: 'ru'
            hl: 'ru'
            num: rsz
            safe: 'high'
            searchType: 'image'
            q: txt
        json: true
    .then (res) ->
        #logger.debug JSON.stringify res
        res.items

module.exports =
    name: 'Images'
    pattern: /!(покажи|пик|img|pic|moar|моар|more|еще|ещё)(?: (.+))?/
    isConf: true

    onMsg: (msg, safe) ->
        txt = msg.match[2]
        if not txt? and msg.reply_to_message?.text?
            txt = msg.reply_to_message.text
        if not txt? and msg.match[1].toLowerCase() in ['moar', 'моар', 'more', 'еще', 'ещё']
            txt = @lastText
        if not txt?
            return
        @lastText = txt
        key = txt + "$$" + msg.chat.id
        if key not of keys
            keys[key] = true
            res = search(txt)
        else
            logger.info "Repeated: #{key}"
            res = search(txt, 8)
        safe(res).then (results) =>
            if not results? or results.length == 0
                msg.reply("Ничего не найдено!")
            else
                result = misc.randomChoice results
                url = result.link #result.unescapedUrl
                @sendImageFromUrl msg, url, reply: msg.id

    onError: (msg) ->
        msg.send('Поиск не удался...')