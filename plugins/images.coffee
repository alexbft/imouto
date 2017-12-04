logger = require 'winston'
config = require '../lib/config'
misc = require '../lib/misc'

search = (txt, rsz = 1, offset = 1) ->
    misc.get "https://www.googleapis.com/customsearch/v1?",
        qs:
            key: config.options.googlekey
            cx: config.options.googlecx
            gl: 'ru'
            hl: 'ru'
            num: rsz
            start: offset
            safe: 'high'
            searchType: 'image'
            q: txt
        json: true
    .then (res) ->
        #logger.debug JSON.stringify res
        res.items

firstKeyboard = [
    [
        {text: 'Следующая', callback_data: 'next'}
    ]
]

lastKeyboard = [
    [
        {text: 'Предыдущая', callback_data: 'prev'}
    ]
]

pageKeyboard = [
    [
        {text: 'Предыдущая', callback_data: 'prev'}
        {text: 'Следующая', callback_data: 'next'}
    ]
]

module.exports =
    name: 'Images'
    pattern: /!(покажи|пик|пек|img|pic|moar|моар|more|еще|ещё)(?: (.+))?/
    isConf: true

    updateInline: (context) ->
        context.msg.edit context.pic.link,
            inlineKeyboard: context.keyboard

    sendInline: (msg, pic, picSet, txt) ->
        url = pic.link #result.unescapedUrl
        context =
            txt: txt
            pic: pic
            picSet: picSet
            index: picSet.indexOf(pic)
            keyboard: firstKeyboard,
            isDisabled: false
        msg.send url,
            inlineKeyboard: context.keyboard,
            callback: (cb, msg) => @onCallback context, cb, msg

    onCallback: (context, cb, msg) ->
        if context.isDisabled
            cb.answer ''
            return

        context.msg = msg
        switch cb.data
            when 'prev'
                if context.index > 1
                    context.index -= 1
                else
                    logger.debug 'disable prev button'
                    context.index = 0
                    context.keyboard = firstKeyboard
                context.pic = context.picSet[context.index]
                @updateInline context
                cb.answer ''
            when 'next'
                res = new Promise (res) => 
                    if context.index + 1 < context.picSet.length
                        context.index += 1
                        context.keyboard = pageKeyboard
                        res()
                    else
                        logger.debug 'make new request'
                        context.isDisabled = true
                        @search(context.txt, context.picSet.length).then (results) =>
                            context.isDisabled = false
                            context.index = context.picSet.length + 1
                            context.picSet = context.picSet.concat(results)
                            res()


                res.then () =>
                    context.pic = context.picSet[context.index]
                    @updateInline context
                    cb.answer ''

    search: (txt, offset) ->
        search(txt, 8, offset)

    onMsg: (msg, safe) ->
        txt = msg.match[2]
        if not txt? and msg.reply_to_message?.text?
            txt = msg.reply_to_message.text
        if not txt?
            return
        res = @search txt

        safe(res).then (results) =>
            if not results? or results.length == 0
                msg.reply("Ничего не найдено!")
            else
                result = results[0]
                @sendInline msg, result, results, txt

    onError: (msg) ->
        msg.send('Поиск не удался...')