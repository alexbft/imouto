misc = require '../lib/misc'
xmldoc = require 'xmldoc'

search = (txt, kind) ->
    misc.google "site:www.animenewsnetwork.com/encyclopedia/#{kind} #{txt}"
    .then (results) ->
        for r in results
            url = r.unescapedUrl
            if kind == 'anime'
                pat = /^http:\/\/www\.animenewsnetwork\.com\/encyclopedia\/anime\.php\?id=(\d+)$/
            else
                pat = /^http:\/\/www\.animenewsnetwork\.com\/encyclopedia\/manga\.php\?id=(\d+)$/
            match = pat.exec url
            if match?
                return match[1]
        null

query = (id, kind) ->
    misc.get("http://cdn.animenewsnetwork.com/encyclopedia/api.xml?#{kind}=#{id}").then (res) ->
        new xmldoc.XmlDocument res

module.exports =
    name: 'Anime'
    pattern: /!(аниме|anime|манга|manga) (.+)/

    onMsg: (msg, safe) ->
        if msg.match[1] in ['аниме', 'anime']
            kind = 'anime'
        else
            kind = 'manga'
        txt = msg.match[2]
        safe(search(txt, kind)).then (id) ->
            if id?
                safe(query(id, kind)).then (xml) ->
                    url = "http://www.animenewsnetwork.com/encyclopedia/#{kind}.php?id=#{id}"
                    details = xml.firstChild
                    title = details.childWithAttribute('type', 'Main title').val
                    imgs = details.childWithAttribute('type', 'Picture').childrenNamed('img')
                    year = details.childWithAttribute('type', 'Vintage').val
                    rating = details.childNamed('ratings')?.attr['weighted_score'] ? 'not rated'
                    img = null
                    maxwidth = null
                    for ii in imgs
                        width = Number ii.attr.width
                        if not maxwidth? or maxwidth < width
                            maxwidth = width
                            img = ii.attr.src
                    descr = details.childWithAttribute('type', 'Plot Summary')?.val ? ''
                    answer = "#{title} (#{year}) :: #{rating}\n#{url}\n\n#{descr}"
                    photoP = safe misc.download img
                    msg.send(answer, preview: false).then ->
                        photoP.then (photo) ->
                            msg.sendPhoto photo, caption: title
            else
                msg.reply('Ничего не найдено!')

    onError: (msg) ->
        msg.send 'Я умею патчить KDE под FreeBSD.'

