misc = require '../lib/misc'

posts = (q) ->
    options =
        json: true
        qs:
            limit: 32
    if q?
        options.qs.tags = q
    misc.get "http://danbooru.donmai.us/posts.json", options

module.exports =
    name: 'Danbooru'
    pattern: /!(няша|nyasha)(?:\s+(.+))?/

    onMsg: (msg, safe) ->
        q = msg.match[2]
        safe posts(q)
        .then (ps) =>
            if ps.length == 0
                msg.send("Ничего не найдено...")
            else
                p = misc.randomChoice(ps)
                if p.large_file_url?
                    url = "http://danbooru.donmai.us#{p.large_file_url}"
                else
                    url = p.source
                @sendImageFromUrl msg, url

    onError: (msg) ->
        msg.send("Рано тебе еще такое смотреть!")
