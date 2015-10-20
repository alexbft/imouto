logger = require 'winston'

config = require '../lib/config'
misc = require '../lib/misc'

keys = {}

search = (txt, num=1) ->
    misc.get "https://www.googleapis.com/youtube/v3/search",
        qs:
            part: 'snippet'
            type: 'video'
            maxResults: num
            key: config.options.googlekey
            q: txt
        json: true
        silent: true
    .then (json) -> json.items

module.exports =
    name: 'YouTube'
    pattern: /!(youtube|видео|клип|video|yt|ютуб) (.+)/

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
            if results?.length == 0
                msg.reply("Ничего не найдено!")
            else
                result = misc.randomChoice results
                url = "https://www.youtube.com/watch?v=" + result.id.videoId
                msg.send url

    onError: (msg) ->
        msg.send "Посмотрите лучше Nyan Cat: https://www.youtube.com/watch?v=wZZ7oFKsKzY"