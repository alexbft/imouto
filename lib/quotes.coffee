logger = require 'winston'

fs = require 'fs'
misc = require './misc'
msgCache = require './msg_cache'

exports.QUOTE_MERGE_TIMEOUT = QUOTE_MERGE_TIMEOUT = 200

quotes = []
initialized = false
fn = null
lastMsg = {}

exports.init = ->
    if not initialized
        fn = __dirname + '/../data/quotes3.txt'
        if fs.existsSync fn
            content = fs.readFileSync fn
            quotes = JSON.parse content
        initialized = true        
    return

getNextNum = ->
    if quotes.length == 0
        1
    else
        maxNum = Math.max.apply Math, quotes.map (q) -> q.num
        maxNum + 1

fromMsg = (msg) ->
    id: msg.message_id
    text: msg.text
    sender: msg.forward_from?.id ? msg.from.id
    sender_name: if msg.forward_from? then misc.fullName(msg.forward_from) else misc.fullName(msg.from)
    chat_id: msg.chat.id
    date: msg.date * 1000

exports.add = (msg, posterId) ->
    if not initialized
        throw new Error "not initialized"
    num = getNextNum()
    date = Date.now()

    quote =
        num: num
        version: 4
        posterId: posterId
        date: date
        messages: [fromMsg(msg)]

    if msg.reply_to_message?
        quote.messages.unshift fromMsg msg.reply_to_message

    # reply_id: msg.reply_to_message?.message_id
    # reply_text: msg.reply_to_message?.text
    # reply_sender: msg.reply_to_message?.from.id
    # reply_sender_name: if msg.reply_to_message? then misc.fullName(msg.reply_to_message.from) else undefined
    # reply_chat_id: msg.reply_to_message?.chat.id

    ii = -1
    # msgI = quote.messages.length - 1
    # for q, i in quotes
    #     isMatch = (
    #         (not q.version? or (q.version == 2 and q.text != null)) and
    #         ((q.text ? null) == (quote.messages[msgI].text ? null) and q.sender == quote.messages[msgI].sender or
    #         (q.reply_text? and q.reply_text == quote.messages[0].text)))
    #     if isMatch
    #         ii = i
    #         break

    # if ii == -1
    for q, i in quotes
        if q.version == 3
            isMatch = true
            for qmsg, j in q.messages
                quotemsg = quote.messages[j]
                if not (qmsg.text? and qmsg.text == quotemsg.text and qmsg.sender == quotemsg.sender)
                    isMatch = false
                    break
            if isMatch 
                if q.messages.length == quote.messages.length
                    logger.info "Duplicate quote: #{q.num}"
                    if q.posterId == posterId
                        lastMsg[posterId] =
                            date: quote.date
                            quoteNum: q.num
                    return q.num

    if ii != -1
        quote.num = quotes[ii].num
        quotes[ii] = quote
    else
        if lastMsg[posterId]?.date? and date - lastMsg[posterId].date < QUOTE_MERGE_TIMEOUT
            newQ = quote
            quote = getByNumber(lastMsg[posterId].quoteNum)
            quote.date = newQ.date
            quote.messages = quote.messages.concat(newQ.messages)
        else
            quotes.push(quote)
    lastMsg[posterId] =
        date: quote.date
        quoteNum: quote.num
    saveQuotes()
    return quote.num

exports.getByNumber = getByNumber = (num) ->
    (q for q in quotes when q.num == num)[0]

hasText = (q, lookFor) ->
    if not q.version? or q.version < 3
        q.text? and q.text.toLowerCase().indexOf(lookFor) != -1 or
        q.sender_name? and q.sender_name.toLowerCase().indexOf(lookFor) != -1 or
        q.saved_name? and q.saved_name.toLowerCase().indexOf(lookFor) != -1 or
        q.reply_text? and q.reply_text.toLowerCase().indexOf(lookFor) != -1 or
        q.reply_sender_name? and q.reply_sender_name.toLowerCase().indexOf(lookFor) != -1
    else
        q.messages.some (m) ->
            m.text? and m.text.toLowerCase().indexOf(lookFor) != -1 or
            m.sender_name? and m.sender_name.toLowerCase().indexOf(lookFor) != -1 or
            m.saved_name? and m.saved_name.toLowerCase().indexOf(lookFor) != -1

exports.getByText = (text, ownerId) ->
    lookFor = text.toLowerCase()
    qq = (q for q in quotes when hasText(q, lookFor))
    if ownerId?
        qq = _getByOwnerId(qq, ownerId)
    misc.randomChoice qq

hasSender = (q, ownerId) ->
    if not q.version? or q.version < 3
        q.sender == ownerId or q.reply_sender == ownerId
    else
        q.messages.some (m) -> m.sender == ownerId

_getByOwnerId = (quotes, ownerId) ->
    (q for q in quotes when hasSender(q, ownerId))

exports.getByOwnerId = (ownerId) ->
    misc.randomChoice _getByOwnerId(quotes, ownerId)

exports.getRandom = ->
    misc.randomChoice quotes

lastUsersUpdate = null
exports.updateUsers = ->
    if lastUsersUpdate? and Date.now() - lastUsersUpdate < 10000
        return
    lastUsersUpdate = Date.now()
    updates = {}
    for quote in quotes
        if not quote.version? or quote.version <= 2
            if quote.sender?
                user = msgCache.getUserById(quote.sender)
                if user?
                    userName = misc.fullName(user)
                    if userName != quote.sender_name
                        if not quote.sender of updates
                            updates[quote.sender] = true
                            logger.info "Quotes: user #{quote.sender} changed name to #{userName}."
                        if userName == 'Unknown' or userName == ''
                            quote.saved_name = quote.sender_name
                        quote.sender_name = userName
            if quote.reply_sender?
                user = msgCache.getUserById(quote.reply_sender)
                if user?
                    userName = misc.fullName(user)
                    if userName != quote.reply_sender_name
                        if not quote.reply_sender of updates
                            updates[quote.reply_sender] = true
                            logger.info "Quotes: user #{quote.reply_sender} changed name to #{userName}."
                        quote.reply_sender_name = userName
        else if quote.version >= 3
            for msg in quote.messages
                if msg.sender?
                    user = msgCache.getUserById(msg.sender)
                    if user?
                        userName = misc.fullName(user)
                        if userName != msg.sender_name
                            if not msg.sender of updates
                                updates[msg.sender] = true
                                logger.info "Quotes: user #{msg.sender} changed name to #{userName}."
                            if userName == 'Unknown' or userName == ''
                                msg.saved_name = quote.sender_name
                            msg.sender_name = userName
    if Object.keys(updates).length > 0
        saveQuotes()
    return

saveQuotes = ->
    fs.writeFileSync fn, JSON.stringify(quotes)

# exports.importSavedNames = ->
#     ffn = __dirname + '/../data/quotes2.txt'
#     quotesOld = JSON.parse fs.readFileSync ffn
#     for q in quotesOld
#         if q.sender_name != '' and q.sender_name != 'Unknown'
#             qNew = getByNumber(q.num)
#             if qNew?
#                 if qNew.version >= 3
#                     for mm in qNew.messages
#                         if mm.sender_name == '' or mm.sender_name == 'Unknown'
#                             mm.saved_name = q.sender_name
#                 else
#                     if qNew.sender_name == '' or qNew.sender_name == 'Unknown'
#                         qNew.saved_name = q.sender_name
#     saveQuotes()
#     logger.info("Done!")

# exports.importSavedNames = ->
#     for q in quotes
#         if q.version >= 3
#             for m in q.messages
#                 if m.date < 14375020580
#                     m.date = m.date * 1000
#     saveQuotes()
#     logger.info "Done"

exports.delQuote = (num) ->
    quotes = (q for q in quotes when q.num != num)
    saveQuotes()
    return

exports.getByNumberPlus = (num) ->
    misc.randomChoice (q for q in quotes when q.num >= num)

getAuthor = (q) ->
    if q.version? and q.version >= 3
        msg = q.messages[q.messages.length - 1]
    else
        msg = q
    msg.saved_name ? msg.sender_name

MOON = String.fromCodePoint(0x1F31D)

exports.getStats = ->
    authors = {}
    for q in quotes
        a = getAuthor(q)
        authors[a] = (authors[a] ? 0) + 1
    authorTuples = ([k, v] for k, v of authors)
    authorTuples.sort ([k1, v1], [k2, v2]) -> v2 - v1
    authorScore = ("#{a} #{MOON} #{v} #{MOON}" for [a, v] in authorTuples.slice(0, 5))
    "Всего цитат: #{quotes.length}\n\nTop 5 авторов:\n" + authorScore.join("\n")
