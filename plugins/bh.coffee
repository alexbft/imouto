logger = require 'winston'

msgCache = require '../lib/msg_cache'
misc = require '../lib/misc'

HIKKA = ['хикка', 'омега', 'корзинка', 'сыч', 'ероха', 'сыночка-корзиночка', 'доченька-боченька', 'новичок']
MAX_PERIOD = 24 * 3600 * 1000
SMALL_PERIOD = 5 * 60 * 1000

smiles =
    sunglasses: String.fromCodePoint 0x1F60E
    unamused: String.fromCodePoint 0x1F612
    angry: String.fromCodePoint 0x1F620
    rage: String.fromCodePoint 0x1F621
    tengu: String.fromCodePoint 0x1F47A
    boom: String.fromCodePoint 0x1F4A5

randomHikka = ->
    misc.randomChoice HIKKA

newStats = (userId) ->
    id: userId
    tyan: false
    moments: []
    status: randomHikka()

removeOldMoments = (stats, now) ->
    stats.moments = (m for m in stats.moments when now - m < MAX_PERIOD)
    
addMoment = (stats, now) ->
    removeOldMoments stats, now
    stats.moments.push(now)
    
calculateBhLevel = (userId, moments, now) ->
    if userId in [89014714]  #алексей
        return 5
    prev = 0
    peaks = []
    for m in moments
        if m - prev > SMALL_PERIOD
            peaks.push(1)
        else
            peaks[peaks.length - 1] += 1
        prev = m
    logger.debug JSON.stringify peaks
    if peaks.length == 0
        0
    else
        if now - prev > SMALL_PERIOD
            peaks.length
        else
            peaks.length - 1 + peaks[peaks.length - 1]
        
bhToString = (bh) ->
    switch bh
        when 0
            icon: smiles.sunglasses
            text: misc.randomChoice ['спокойствие', 'нирвана', 'будда', 'нулевой']
        when 1
            icon: smiles.unamused
            text: misc.randomChoice ['покалывание', 'легкий', 'недоволен', 'незначительный']
        when 2
            icon: smiles.angry
            text: misc.randomChoice ['печёт!', 'раскаляется', 'нешуточный', 'дымится']
        when 3
            icon: smiles.rage
            text: misc.randomChoice ['адский!', 'страшный!', 'красная тревога!', 'термоядерный!', 'стул плавится!']
        when 4
            icon: smiles.tengu
            text: misc.randomChoice ['Первая Космическая!', 'Сатанинский!', 'Титанический!', 'Убить Всех Человеков']
        else
            icon: smiles.boom
            text: 'FFFFUUUUUU!!! ' + smiles.rage + smiles.rage + smiles.rage

getUserId = (msg) ->
    if msg.reply_to_message?
        tmp = msgCache.tryResolve msg.reply_to_message
        if tmp?
            if tmp.forward_from?
                tmp.forward_from.id
            else
                tmp.from.id
        else
            msg.from.id
    else
        msg.from.id

module.exports =
    name: 'Bugurt'
    pattern: /!(bh|статус|кто|хто|это|тян|кун|бугурт|багор|багет|бомбит|багратион|бамболейло|батруха|баттхерт|бантустан|бранденбург|будапешт|будда|баргест|блюменталь|бакенбард|боль|бубалех|печет|печёт|припекло|пиздец|бля|сука|спок|горит|жжет|жжёт|пригорело|ору|f+u+)(.*)/
    
    init: ->
        @stats = misc.loadJson('bh_stats') ? {}
    
    onMsg: (msg) ->
        if msg.match[1].toLowerCase() == 'bh'
            return @handleAdmin msg
        if msg.match[1].toLowerCase() == 'статус'
            return @handleStatus msg
        if msg.match[1].toLowerCase() in ['кто', 'хто']
            return @handleWhois msg
        if msg.match[1].toLowerCase() == 'это'
            return @handleThisis msg
        userId = msg.from.id
        stats = @stats[userId] ?= newStats(userId)
        if (msg.match[1].toLowerCase() == 'тян' and stats.tyan) or (msg.match[1].toLowerCase() == 'кун' and not stats.tyan)
            @report msg, stats, 0
        else
            now = Date.now()
            if msg.match[1].toLowerCase() in ['спок', 'будда']
                stats.moments = []
            else
                addMoment(stats, now)
            bhLevel = calculateBhLevel userId, stats.moments, now
            @report msg, stats, bhLevel
            misc.saveJson 'bh_stats', @stats
            
    report: (msg, stats, bh, otherUserName = null) ->
        {icon, text} = bhToString bh
        label = if otherUserName? then "Статус #{otherUserName}" else "Ваш статус"
        msg.reply "#{label}: #{stats.status}\nУровень бугурта: #{icon} - #{text}"
        
    handleAdmin: (msg) ->
        if not @isSudo msg
            return
        params = msg.match[2].substr(1)
        [id, st, tyan] = params.split(' ')
        @stats[id] ?= newStats(Number(id))
        @stats[id].status = st if st?
        if tyan?
            @stats[id].tyan = tyan == '1'
        msg.reply "Статус #{id} обновлён."
        misc.saveJson 'bh_stats', @stats
        
    handleStatus: (msg) ->
        if msg.match[2]? and msg.match[2].startsWith ' '
            if @isSudo msg
                userId = getUserId msg
            else
                userId = msg.from.id
            stats = @stats[userId] ?= newStats(userId)
            stats.status = msg.match[2].substr(1)
            if userId == msg.from.id
                msg.reply 'Ваш статус обновлён.'
            else
                name = msgCache.getUserById(userId).first_name
                msg.reply "Статус #{name} обновлён."
            misc.saveJson 'bh_stats', @stats
        else
            userId = getUserId msg
            stats = @stats[userId] ?= newStats(userId)
            now = Date.now()
            removeOldMoments stats, now
            bhLevel = calculateBhLevel userId, stats.moments, now
            name = if userId != msg.from.id then msgCache.getUserById(userId).first_name else null
            @report msg, stats, bhLevel, name

    handleWhois: (msg) ->
        userId = getUserId msg
        stats = @stats[userId] ?= newStats userId
        if @isSudo(msg) and stats.whoisAdm?
            name = stats.whoisAdm
        else
            name = stats.whois ? msgCache.getUserById(userId).first_name
        if name? and name != ''
            msg.reply "Это #{name}, #{stats.status}."
        else
            msg.reply "Первый раз вижу..."

    handleThisis: (msg) ->
        if not (msg.match[2]? and msg.match[2].startsWith ' ')
            return
        whois = msg.match[2].substr(1)
        userId = getUserId msg
        stats = @stats[userId] ?= newStats(userId)
        stats.whois = whois
        if @isSudo(msg)
            stats.whoisAdm = whois
        misc.saveJson 'bh_stats', @stats
        msg.reply "Запомнила, это #{whois}."

