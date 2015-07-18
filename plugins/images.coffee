logger = require 'winston'
misc = require '../lib/misc'

keys = {}

search = (txt, rsz = 1) ->
    misc.get "http://ajax.googleapis.com/ajax/services/search/images",
        qs:
            v: '1.0'
            hl: 'ru'
            rsz: rsz
            imgsz: 'small|medium|large|xlarge'
            safe: 'active'
            q: txt
        json: true
    .then (res) ->
        res.responseData.results

module.exports =
    name: 'Images'
    pattern: /!(покажи|пик|img) (.+)/
    isConf: true

    onMsg: (msg, safe) ->
        txt = msg.match[2]
        key = txt + "$$" + msg.chat.id
        if key not of keys
            keys[key] = true
            res = search(txt)
        else
            logger.info "Repeated: #{key}"
            res = search(txt, 8)
        safe(res).then (results) =>
            if results.length == 0
                msg.reply("Ничего не найдено!")
            else
                result = misc.randomChoice results
                url = result.unescapedUrl
                @sendImageFromUrl msg, url, reply: msg.id

    onError: (msg) ->
        msg.send('Поиск не удался...')