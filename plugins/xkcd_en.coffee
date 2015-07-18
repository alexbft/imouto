misc = require '../lib/misc'
pq = require '../lib/promise'

getJson = (url) ->
    misc.get url, json: true

module.exports =
    name: 'XKCD (en)'
    pattern: /!xkcd en(?: (\d+))?$/

    onMsg: (msg, safe) ->
        num = misc.tryParseInt msg.match[1]
        if num?
            getNum = pq.resolved(num)
        else
            getNum = getJson("http://xkcd.com/info.0.json").then (json) -> misc.random(json.num) + 1
        safe(getNum).then (num) ->
            safe getJson "http://xkcd.com/#{num}/info.0.json"
            .then (json) ->
                msg.send "#{json.num}. #{json.title}\n#{json.img}"
                .then (sent) ->
                    msg.send json.alt, reply: sent.message_id, preview: false

    onError: (msg) ->
        msg.send "Комикс не найден."
