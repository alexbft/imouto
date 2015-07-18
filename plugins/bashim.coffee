misc = require '../lib/misc'
iconv = require 'iconv-lite'

module.exports =
    name: 'bash.im'
    pattern: /!(баш|bash)\b[\s]*(\d+)?/

    onMsg: (msg, safe) ->
        id = msg.match[2]
        if not id?
            res = misc.getAsBrowser "http://bash.im/forweb/?u"
            .then (page) ->
                id = page.match(/bash.im\/quote\/(\d+)/)[1]
                text = page.match(/0;">([^]+?)<\' \+ \'\/div>/)[1]
                [id, text.replace(/<' \+ 'br>/g, '\n').replace(/<' \+ 'br \/>/g, '\n')]
        else
            res = misc.getAsBrowser "http://bash.im/quote/#{id}", encoding: null
            .then (page) ->
                page = iconv.decode(page, 'win1251')
                text = page.match(/<div class="text">([^]+?)<\/div>/)[1]
                [id, text.replace(/<br \/>/g, '\n').replace(/<br>/g, '\n')]
        safe(res).then ([id, text]) ->
            text = "Цитата №#{id}\n\n" + misc.entities.decode text
            msg.send text

    onError: (msg) ->
        msg.send 'Баш уже не тот...'


