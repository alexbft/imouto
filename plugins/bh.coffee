logger = require 'winston'

misc = require '../lib/misc'

HIKKA = ['хикка', 'омега', 'корзинка', 'сыч']
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

module.exports =
    name: 'Bugurt'
    pattern: /!(bh|статус|тян|кун|бугурт|багор|багет|бомбит|багратион|бамболейло|батруха|баттхерт|бантустан|бранденбург|будапешт|будда|баргест|блюменталь|бакенбард|боль|бубалех|печет|печёт|припекло|пиздец|бля|сука|спок|горит|жжет|жжёт|пригорело|ору|f+u+)(.*)/
    
    init: ->
        @stats = misc.loadJson('bh_stats') ? {}
    
    onMsg: (msg) ->
        if msg.match[1].toLowerCase() == 'bh'
            return @handleAdmin msg
        if msg.match[1].toLowerCase() == 'статус'
            return @handleStatus msg
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
            
    report: (msg, stats, bh) ->
        {icon, text} = bhToString bh
        msg.reply "Ваш статус: #{stats.status}\nУровень бугурта: #{icon} - #{text}"
        
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
        userId = msg.from.id
        stats = @stats[userId] ?= newStats(userId)
        if msg.match[2]? and msg.match[2].startsWith ' '
            stats.status = msg.match[2].substr(1)
            msg.reply 'Ваш статус обновлён.'
            misc.saveJson 'bh_stats', @stats
        else
            now = Date.now()
            removeOldMoments stats, now
            bhLevel = calculateBhLevel userId, stats.moments, now
            @report msg, stats, bhLevel
