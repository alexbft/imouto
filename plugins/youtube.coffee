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
    pattern: /!(youtube|видео|клип|video|yt|ютуб)(?: (.+))?/

    onMsg: (msg, safe) ->
        txt = msg.match[2]
        reply_to_id = msg.message_id
        if not txt? and msg.reply_to_message?.text?
            txt = msg.reply_to_message.text
            reply_to_id = msg.reply_to_message.message_id
        if not txt?
            return        
        key = txt + "$$" + msg.chat.id
        if key not of keys
            keys[key] = true
            res = search(txt)
        else
            logger.info "Repeated: #{key}"
            res = search(txt, 8)
        safe(res).then (results) =>
            if results?.length == 0
                msg.send "Ничего не найдено!", reply: reply_to_id
            else
                result = misc.randomChoice results
                url = "https://www.youtube.com/watch?v=" + result.id.videoId
                msg.send url, reply: reply_to_id

    onError: (msg) ->
        msg.send "Посмотрите лучше Nyan Cat: https://www.youtube.com/watch?v=wZZ7oFKsKzY"