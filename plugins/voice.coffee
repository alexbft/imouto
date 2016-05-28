child_process = require 'child_process'
tmp = require 'tmp'
fs = require 'fs'
logger = require 'winston'
Ivona = require 'ivona-node'

ivona = null

config = require '../lib/config'
pq = require '../lib/promise'
misc = require '../lib/misc'

FFMPEG = config.options.ffmpeg

isJap = (c) ->
    return ((c >= '\u3000' and c <= '\u303f') or
        (c >= '\u3040' and c <= '\u309f') or
        (c >= '\u30a0' and c <= '\u30ff') or      
        (c >= '\uff00' and c <= '\uffef') or     
        (c >= '\u4e00' and c <= '\u9faf'))

isKor = (c) ->
    return ((c >= '\u3130' and c <= '\u318f') or
        (c >= '\uac00' and c <= '\ud7af'))

isRus = (c) ->
    c >= 'А' and c <= 'Я' or c >= 'а' and c <= 'я'

#    [en-US, en-IN, tr-TR, ru-RU, ro-RO, pt-PT, pl-PL, nl-NL, it-IT, is-IS, fr-FR, es-ES, de-DE, en-GB-WLS, cy-GB, da-DK, en-AU, pt-BR, nb-NO, sv-SE, es-US, fr-CA, en-GB

googleTts = (txt, lang) ->
    #https://translate.google.com/translate_tts?ie=UTF-8&q=test&tl=en&total=1&idx=0&textlen=4&tk=285616&client=t&prev=input    
    misc.getAsBrowser "https://translate.google.com/translate_tts",
        qs:
            ie: 'UTF-8'
            tl: lang
            q: txt
            total: 1
            idx: 0
            textlen: txt.length
            client: 't'
        encoding: null

ivonaTts = (txt, lang) ->
    df = new pq.Deferred

    lang = {'en': 'en-US', 'ru': 'ru-RU'}[lang]
    if not lang?
        df.resolve(error: 'lang')
    else
        if not ivona?
            [accessKey, secretKey] = config.options.ivona.split ':'
            ivona = new Ivona {accessKey, secretKey}
        voiceStream = ivona.createVoice txt,
            body:
                Voice:
                    Language: lang
                    Gender: 'Female'
                OutputFormat:
                    Codec: 'OGG'
        misc.readStream voiceStream, df.callback()
    df.promise

convertMp3ToOpus = (mp3) ->
    df = new pq.Deferred
    tmpFile = tmp.fileSync postfix: '.ogg'
    tmpFile.removeCallback()
    tmpFile.removeCallback = ->
        fs.unlinkSync tmpFile.name
    args = "-v error -i - -acodec libopus \"#{tmpFile.name}\""
    cmd = "\"#{FFMPEG}\" #{args}"
    logger.info "Running: #{cmd}"
    proc = child_process.exec cmd, (err, stdout, stderr) ->
        if (err) 
            df.reject(err)
        else
            try 
                process.stdout.write(stdout)
                process.stdout.write(stderr)
                df.resolve(tmpFile)
            catch e
                df.reject e
    proc.stdin.write(mp3)
    proc.stdin.end()
    df.promise

module.exports =
    name: 'Voice tts'
    # isConf: true
    # isPrivileged: true
    # warnPrivileged: true
    pattern: /!(голос|войс|voice|speak|v|tts|няк|nya|desu|десу)(?:\s+(.+))?$/

    onMsg: (msg, safe) ->
        txt = msg.match[2]
        if not txt?
            if msg.reply_to_message?.text?
                txt = msg.reply_to_message.text
            else
                logger.info("No text")
                return
        chars = txt.split('')
        #if chars.some isJap
        #    lang = 'ja'
        #else if chars.some isKor
        #    lang = 'ko'
        if chars.some isRus
            lang = 'ru'
        else
            lang = 'en'
        nya = msg.match[1].toLowerCase()
        if nya in ['няк', 'nya', 'desu', 'десу'] and lang in ["ja", "en", "ru"]
            if nya in ['няк', 'nya']
                nya = {"ja": "にゃ", "en": "nyah", "ru": "ня"}[lang]
            else if nya in ['desu', 'десу']
                nya = {"ja": "ですう", "en": "desoo", "ru": "дэсу"}[lang]
            else
                nya = 'wtf'
            txt = txt.replace /([\!\?\.\,])/g, " #{nya}$1"
            if not /([\!\?\.\,])$/.test(txt)
                txt = txt + " #{nya}!"

        if txt.length > 200 and not @isSudo(msg)
            msg.reply("Текст слишком длинный!")
            return
        logger.info "Voicing: #{txt}"
        safe ivonaTts txt, lang
        .then (ogg) =>
            if ogg.error?
                msg.send 'Не знаю такого языка!'
                return
            if ogg.message?
                logger.error ogg.message
            else
                logger.debug "Got bytes: #{ogg.length}"
                #logger.debug "#{ogg}"
                msg.sendVoice ogg

            # safe convertMp3ToOpus mp3
            # .then (opusFile) =>
            #     msg.opusFile = opusFile
            #     safe @sendVoiceFromFile msg, opusFile.name
            #     .then ->
            #         logger.info "Done sending, removing temp file..."
            #         opusFile.removeCallback()

    onError: (msg) ->
        # if msg.opusFile?
        #    opusFile.removeCallback()
        msg.send "Я сегодня не в голосе."