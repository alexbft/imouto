logger = require 'winston'

fs = require 'fs'
misc = require './misc'
msgCache = require './msg_cache'

exports.QUOTE_MERGE_TIMEOUT = QUOTE_MERGE_TIMEOUT = 500

exports.THUMBS_UP = String.fromCodePoint(0x1f44d) + String.fromCodePoint(0x1f3fb)
exports.THUMBS_DOWN = String.fromCodePoint(0x1f44e) + String.fromCodePoint(0x1f3fb)

quotes = []
initialized = false
fn = null
lastMsg = {}
votes = {}
lastQuote = {}

exports.init = ->
    if not initialized
        fn = __dirname + '/../data/quotes3.txt'
        if fs.existsSync fn
            content = fs.readFileSync fn
            quotes = JSON.parse content
        loadVotes()
        initialized = true        
    return

loadVotes = ->
    votes = misc.loadJson('quote_votes') ? {}

saveVotesTimer = null
maybeSaveVotes = ->
    if not saveVotesTimer?
        saveVotesTimer = setTimeout saveVotes, 10000

saveVotes = ->
    saveVotesTimer = null
    logger.debug 'Saving votes...'
    misc.saveJson 'quote_votes', votes

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

getUserNameById = (userId) ->
    user = msgCache.getUserById userId
    if user?
        misc.fullName user
    else
        for q in quotes
            if q.messages?
                for m in q.messages
                    if m.sender == userId
                        return m.sender_name
        null

exports.add = (msg, posterId) ->
    if not initialized
        throw new Error "not initialized"
    num = getNextNum()
    date = Date.now()

    quote =
        num: num
        version: 5
        posterId: posterId
        posterName: getUserNameById(posterId)
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
    # 
    # for q, i in quotes
    #     if isMatch
    #         ii = i
    #         break

    # if ii == -1

    isComplex = false
    if lastMsg[posterId]?.date? and date - lastMsg[posterId].date < QUOTE_MERGE_TIMEOUT
        oldQuoteNum = lastMsg[posterId].quoteNum
        oldQuoteIndex = -1
        for q, i in quotes
            if q.num == oldQuoteNum
                oldQuote = q
                oldQuoteIndex = i
                break
        if oldQuoteIndex != -1
            quote.num = oldQuoteNum
            quote.messages = oldQuote.messages.concat quote.messages
            isComplex = true

    msgI = quote.messages.length - 1
    for q, i in quotes
        if not q.version? or q.version < 3
            if q.reply_text?
                isMatch = quote.messages.length == 2 and q.sender == quote.messages[1].sender and (q.text ? null) == (quote.messages[1].text ? null) and (q.reply_text ? null) == (quote.messages[0].text ? null)
            else
                isMatch = quote.messages.length == 1 and q.sender == quote.messages[0].sender and (q.text ? null) == (quote.messages[0].text ? null)
        else
            isMatch = q.messages.length == quote.messages.length
            if isMatch
                for qmsg, j in q.messages
                    quotemsg = quote.messages[j]
                    if not ((q.version < 5 or qmsg.text?) and qmsg.text == quotemsg.text and qmsg.sender == quotemsg.sender)
                        isMatch = false
                        break
        if isMatch 
            logger.info "Duplicate quote: #{q.num}"
            if q.version == 5
                if q.posterId == posterId
                    lastMsg[posterId] =
                        date: quote.date
                        quoteNum: q.num
                return q.num
            else
                ii = i
                break

    if ii != -1
        quote.num = quotes[ii].num
        if quotes[ii].saved_name?
            for mm in quote.messages
                mm.saved_name = quotes[ii].saved_name
        if quotes[ii].messages?
            for msgI in [0...quotes[ii].messages.length]
                if quotes[ii].messages[msgI].saved_name?
                    quote.messages[msgI].saved_name = quotes[ii].messages[msgI].saved_name
        quotes[ii] = quote
        if isComplex and quotes.length - oldQuoteIndex <= 2
            quotes = (q for q in quotes when q.num != oldQuoteNum)
    else
        if isComplex
            quotes[oldQuoteIndex] = quote
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

getSenders = (q) ->
    dict = {}
    if not q.version? or q.version < 3
        if q.sender?
            dict[q.sender] ?= q.saved_name ? q.sender_name
        if q.reply_sender?
            dict[q.reply_sender] ?= q.reply_sender_name
    else
        for msg in q.messages
            dict[msg.sender] = msg.saved_name ? msg.sender_name
    (v for k, v of dict)

_getByOwnerId = (quotes, ownerId) ->
    (q for q in quotes when hasSender(q, ownerId))

exports.getByOwnerId = (ownerId) ->
    misc.randomChoice _getByOwnerId(quotes, ownerId)

exports.getRandom = ({onlyPositive}) ->
    if onlyPositive
        qq = (q for q in quotes when getRating(q.num) > 0)
    else
        qq = quotes
    misc.randomChoice qq

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
                            if quote.sender_name != 'Unknown' and quote.sender_name != ''
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
            if quote.posterId? and not quote.posterName?
                quote.posterName = getUserNameById(quote.posterId)
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
                                if msg.sender_name != 'Unknown' and msg.sender_name != ''
                                    msg.saved_name = msg.sender_name
                            msg.sender_name = userName
    if Object.keys(updates).length > 0
        saveQuotes()
    return

exports.setSavedName = (userId, name) ->
    for q in quotes
        if q.messages?
            for msg in q.messages
                if msg.sender == userId
                    msg.saved_name = name
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
    if votes[num]?
        delete votes[num]
        maybeSaveVotes()
    return

exports.getByNumberPlus = (num) ->
    misc.randomChoice (q for q in quotes when q.num >= num)

MOON = String.fromCodePoint(0x1F31D)

TOP_AUTHORS = 10
exports.getStats = (ownerId, query) ->
    if ownerId?
        userName = getUserNameById(ownerId)
        len = _getByOwnerId(quotes, ownerId).length
        "#{userName}: #{MOON} #{len} #{MOON} цитат"
    else if not query? or query.trim() == ''
        authors = {}
        for q in quotes
            aus = getSenders(q)
            for a in aus
                if a != ''
                    authors[a] = (authors[a] ? 0) + 1
        authorTuples = ([k, v] for k, v of authors)
        authorTuples.sort ([k1, v1], [k2, v2]) -> v2 - v1
        authorScore = ("#{a} #{MOON} #{v} #{MOON}" for [a, v] in authorTuples.slice(0, TOP_AUTHORS))
        "Всего цитат: #{quotes.length}\nПоследняя цитата: #{getNextNum() - 1}\n\nTop #{TOP_AUTHORS} авторов:\n" + authorScore.join("\n")
    else
        lookFor = query.toLowerCase()
        qq = (q for q in quotes when hasText(q, lookFor))
        "Цитат с упоминанием '#{query}': #{qq.length}"

exports.setLastQuote = (chatId, quoteNum) ->
    lastQuote[chatId] =
        num: quoteNum
        date: Date.now()
    return

exports.vote = (num, chatId, userId, isUp) ->
    if num?
        if not getByNumber(num)?
            return null
    else
        num = lastQuote[chatId]?.num
        lastQuoteTime = lastQuote[chatId]?.date
        if not (lastQuoteTime? and Date.now() - lastQuoteTime < 1000 * 60 * 5)
            return null
    points = if isUp then 1 else -1
    logger.info "User #{userId} voted #{points} for quote ##{num}."
    votes[num] ?= {}
    if votes[num][userId] != points
        votes[num][userId] = points
        maybeSaveVotes()
        num
    else
        null

exports.getRating = getRating = (quoteNum) ->
    rating = 0
    if votes[quoteNum]?
        for k, v of votes[quoteNum]
            rating += v
    rating
