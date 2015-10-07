logger = require 'winston'

quotes = require '../lib/quotes'
misc = require '../lib/misc'
config = require '../lib/config'
tg = require '../lib/tg'

module.exports =
    name: 'Quotes (vote)'
    pattern: /\/(LOYS|FUUU|ЛОЙС|ФУУУ|лайк|дизлайк|like|dislike|palec_VEPH|palec_HU3)(?:(?:_|\s+)(\d+))?/

    init: ->
        quotes.init()

    onMsg: (msg) ->
        isThumbsUp = msg.match[1].toLowerCase() in ["loys", "лойс", "лайк", "like", "palec_veph"]
        num = misc.tryParseInt(msg.match[2])
        num = quotes.vote(num, msg.chat.id, msg.from.id, isThumbsUp)
        if num?
            rating = quotes.getRating(num)
            if rating > 0
                rating = "+#{rating}"
            tg.sendMessage
                chat_id: msg.from.id
                text: "Ваш голос #{if isThumbsUp then quotes.THUMBS_UP else quotes.THUMBS_DOWN} учтён. Рейтинг цитаты №#{num}: [ #{rating} ]"
