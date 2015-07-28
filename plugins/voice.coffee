child_process = require 'child_process'
tmp = require 'tmp'
fs = require 'fs'
logger = require 'winston'

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
    pattern: /!(голос|войс|voice|speak|ня|nya|desu|десу)( [a-z]{2})?(?: (.+))?$/

    onMsg: (msg, safe) ->
        txt = msg.match[3]
        if not txt?
            if msg.reply_to_message?.text?
                txt = msg.reply_to_message.text
            else
                logger.info("No text")
                return
        if msg.match[2]?
            lang = msg.match[2].trim()
        else
            chars = txt.split('')
            if chars.some isJap
                lang = 'ja'
            else if chars.some isKor
                lang = 'ko'
            else if chars.some isRus
                lang = 'ru'
            else
                lang = 'en'
        nya = msg.match[1].toLowerCase()
        if nya in ['ня', 'nya', 'desu', 'десу'] and lang in ["ja", "en", "ru"]
            if nya in ['ня', 'nya']
                nya = {"ja": "にゃ", "en": "nyah", "ru": "ня"}[lang]
            else if nya in ['desu', 'десу']
                nya = {"ja": "ですう", "en": "desoo", "ru": "дэсу"}[lang]
            else
                nya = 'wtf'
            txt = txt.replace /([\!\?\.\,])/g, " #{nya}$1"
            if not /([\!\?\.\,])$/.test(txt)
                txt = txt + " #{nya}!"

        if txt.length > 128 and not @isSudo(msg)
            msg.reply("Текст слишком длинный!")
            return
        logger.info "Voicing: #{txt}"
        safe googleTts txt, lang
        .then (mp3) =>
            logger.debug "Got bytes: #{mp3.length}"
            safe convertMp3ToOpus mp3
            .then (opusFile) =>
                msg.opusFile = opusFile
                safe @sendAudioFromFile msg, opusFile.name
                .then ->
                    logger.info "Done sending, removing temp file..."
                    opusFile.removeCallback()

    onError: (msg) ->
        if msg.opusFile?
            opusFile.removeCallback()
        msg.send "Я сегодня не в голосе."