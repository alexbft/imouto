misc = require '../lib/misc'

module.exports =
    name: 'VNDB'
    pattern: /!(vn|вн)(?: (.+))?$/

    onMsg: (msg, safe) ->
        if msg.match[2]?
            q = msg.match[2]
            qq = encodeURIComponent(q)
            safe misc.get "https://vndb.org/v/all?o=d;s=pop;q=#{qq}"
            .then (page) =>
                mm = page.match /<td class="tc1"><a href="(.*?)"/
                if mm?
                    @parseVnFrom msg, safe, "https://vndb.org#{mm[1]}"
                else
                    @parseVn msg, page
        else
            @parseVnFrom msg, safe, "https://vndb.org/v/rand"

    parseVnFrom: (msg, safe, url) ->
        safe misc.get url
        .then (page) => @parseVn msg, page

    parseVn: (msg, page) ->
        title = page.match(/<title>(.+?)<\/title>/)[1]
        img = "https://s.vndb.org/" + page.match(/<img src="\/\/s\.vndb\.org\/(.+?)"/)[1]
        descr = page.match(/<h2>Description<\/h2><p>([^]+?)<\/p>/)[1].replace(/<br \/>/g, '\n')
            .replace(/<a href="(.+?)"([^]+?)<\/a>/g, '$1')
        url = "https://vndb.org" + page.match(/<li class="tabselected"><a href="(.+?)"/)[1]
        msg.send("#{title}\n#{url}\n\n#{descr}", preview: false).then =>
            @sendImageFromUrl msg, img, caption: title

    onError: (msg) ->
        msg.send "Китайские порноальбомы - не нужны."