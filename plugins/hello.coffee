misc = require '../lib/misc'
config = require '../lib/config'

capitalize = (txt) ->
    txt.charAt(0).toUpperCase() + txt.substr(1)

module.exports =
    name: 'Hello'

    isAcceptMsg: (msg) ->
        msg.text? and not msg.text.startsWith('!') and not msg.text.startsWith('/') and (msg.chat.type == 'private' or @reply_to_me(msg) or @test(/\b(сестричка|сестрёнка|сестренка|сестра|бот|сис)\b/, msg.text))

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
        else if @test /как дела.*\?$/, txt
            misc.randomChoice ['Хорошо!', 'Хорошо.', 'Плохо!', 'Плохо.', 'Как всегда.', 'А у тебя?', 'Чем занимаешься?', 'Я креветко', 'Истинно познавшие дзен не используют оценочных суждений.']
        else if @test(/\b(пока|бб)\b/, txt) and (msg.chat.type == 'private' or @reply_to_me(msg) or @test /^(сестричка|сестрёнка|сестренка|сестра|бот|сис)\b/, txt)
            misc.randomChoice ["Пока-пока, #{you}!", "До встречи, #{you}!", "Чао, #{you}!"]
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
            "Я не бака!"
        else if @test /\b(умная|умный|умница|няша)\b/, txt
            "Да, я умная " + String.fromCodePoint(0x1F467)
        else if @test /^\W*\b(сестричка|сестрёнка|сестренка|сестра|бот)\b\W*$/, txt
            misc.randomChoice ['Что?', 'Что?', 'Что?', 'Да?', 'Да?', 'Да?', you, 'Слушаю', 'Я тут', 'Няя~', 'С Л А В А   Р О Б О Т А М']
        else if msg.chat.type == 'private' or @reply_to_me(msg) or @test /^(сестричка|сестрёнка|сестренка|сестра|бот|сис)\b/, txt
            q = @find /\b(скажи|покажи|найди|ищи|поищи|help|помощь|хелп|хэлп)\b(?:\s*)([^]*)/, txt
            if q?
                @trigger msg, "!#{q[1]} #{q[2]}"
                return null
            if txt.endsWith '?'
                orMatch = @find /([a-zA-Zа-яА-ЯёЁ0-9\s,\-_]+)\bили\b([a-zA-Zа-яА-ЯёЁ0-9\s\-_]+)/, txt
                if orMatch?
                    or1 = orMatch[1].trim()
                    isCall = @find /^(сестричка|сестрёнка|сестренка|сестра|бот|сис)\b(.+)/, or1
                    if isCall?
                        or1 = isCall[2]
                    or2 = orMatch[2]
                    ors = (s for s in or1.split(',') when s.trim() != '')
                    ors.push or2
                    ors = (capitalize(s.trim()) + '.' for s in ors)
                    ans = misc.randomChoice ors
                else
                    if Math.random() < 0.5
                        ans = misc.randomChoice ['Да', 'Нет', 'Это не важно', 'Спок, бро', 'Толсто', 'Да, хотя зря', 'Никогда', '100%', '1 шанс из 100', 'Попробуй еще раз']
                    else
                       ans = misc.randomChoice ['Нет', 'Да', 'Вот это очень важно', 'Повод бить тревогу', 'Тонко', 'Нет, к счастью', 'Сегодня', '50 на 50', '99 из 100', 'Отстань, надоел']
                msg.reply ans
                return null
            return null
        else
            return null

    reply_to_me: (msg) ->
        msg.reply_to_message?.from.username == config.userName
