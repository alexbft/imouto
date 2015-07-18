iconv = require 'iconv-lite'

misc = require '../lib/misc'

getPage = (url) ->
    misc.get url, encoding: null
    .then (buf) -> iconv.decode buf, 'win1251'

module.exports =
    name: 'nya.sh'
    pattern: /!(няш|мяш|няшмяш)\b/

    onMsg: (msg, safe) ->
        if msg.match[1].toLowerCase() == 'няшмяш'
            @trigger msg, '!покажи няшмяш'
        else if msg.match[1].toLowerCase() == 'мяш'
            num = misc.random(3404) + 1
            @sendPic msg, safe, num
        else
            num = misc.random(8087) + 1
            @sendPost msg, safe, num

    sendPic: (msg, safe, num) ->
        safe getPage("http://nya.sh/pic/#{num}")
        .then (page) =>
            url = "http://nya.sh" + page.match(/<img src="([^"]+?)" alt="pic" class="irl" \/>/)[1]
            @sendImageFromUrl msg, url, caption: "http://nya.sh/pic/#{num}"

    sendPost: (msg, safe, num) ->
        safe getPage("http://nya.sh/post/#{num}")
        .then (page) =>
            text = page.match(/<div class="content">([^]+?)<\/div>/)[1].replace(/<br \/>/g, '')
            text = misc.entities.decode text
            text = "Цитата №#{num}\n\n" + text
            msg.send text

    onError: (msg) ->
        msg.send "Ошибка! Ньоро~н..."
