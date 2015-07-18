misc = require '../lib/misc'
config = require '../lib/config'

module.exports =
    name: 'Hello'

    isAcceptMsg: (msg) ->
        msg.text? and not msg.text.startsWith('!') and not msg.text.startsWith('/') and (msg.chat.first_name? or @reply_to_me(msg) or @test(/\b(сестричка|сестрёнка|сестренка|сестра|бот)\b/, msg.text))

    onMsg: (msg) ->
        #console.log("Hellowing")
        res = @go(msg)
        if res
            msg.send res

    test: (pat, txt) ->
        @fixPattern(pat).test txt

    find: (pat, txt) ->
        @fixPattern(pat).exec txt

    go: (msg) ->
        txt = msg.text.trim()
        you = msg.from.first_name

        if @test(/\b(привет|прив\b)/, txt) and not @test(/\bбот\b/, txt)
            "Привет, #{you}!"
        else if @test /\b(пока|бб)\b/, txt
            "Пока-пока, #{you}!"
        else if @test /\b(спасибо|спс)\b/, txt
            if Math.random() < 0.5
                "Не за что, #{you}!"
            else
                "Пожалуйста, #{you}!"
        else if @test /\b(споки|спокойной ночи)\b/, txt
            night = misc.randomChoice ['Спокойной ночи', 'Сладких снов', 'До завтра']
            "#{night}, #{you}!"
        else if @test /\b(глупая|глупый)\b/, txt
            "Я не глупая!"
        else if @test /\b(тупая|тупой)\b/, txt
            "Я не тупая!"
        else if @test /\b(дура|дурак)\b/, txt
            "Я не дура!"
        else if @test /\bбака\b/, txt
            "Я не bбака!"
        else if @test /\b(умная|умный)\b/, txt
            "Да, я умная " + String.fromCodePoint(0x1F467)
        else if @test /^\W*\b(сестричка|сестрёнка|сестренка|сестра|бот)\b\W*$/, txt
            misc.randomChoice ['Что?', 'Что?', 'Что?', 'Да?', 'Да?', 'Да?', you, 'Слушаю', 'Я тут', 'Няя~', 'С Л А В А   Р О Б О Т А М']
        else if msg.chat.first_name? or @reply_to_me(msg) or @test /^(сестричка|сестрёнка|сестренка|сестра|бот)\b/, txt
            q = @find /\b(скажи|покажи|переведи|найди|ищи|поищи|help|помощь|хелп|хэлп)\b(?:\s*)([^]*)/, txt
            if q?
                @trigger msg, "!#{q[1]} #{q[2]}"
                return null
            if txt.endsWith '?'
                ans = misc.randomChoice ['Да', 'Нет', 'Это не важно', 'Спок, бро', 'Толсто', 'Да, хотя зря', 'Никогда', '100%', '1 шанс из 100', 'Попробуй еще раз']
                msg.reply ans
                return null
            return null
        else
            return null

    reply_to_me: (msg) ->
        msg.reply_to_message?.from.username == config.userName