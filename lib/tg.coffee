logger = require 'winston'

msgCache = require './msg_cache'
query = require './query'

exports.sendMessage = (args) ->
    logger.outMsg "(#{args.chat_id}) <<< #{args.text}"
    if args.reply_markup?
        #logger.debug "Keyboard: #{JSON.stringify args.reply_markup}"
        args.reply_markup = JSON.stringify args.reply_markup
    query 'sendMessage', args

exports.editMessageText = (args) ->
    logger.outMsg "(#{args.chat_id}) (edit #{args.message_id}) <<< #{args.text}"
    if args.reply_markup?
        #logger.debug "Keyboard: #{JSON.stringify args.reply_markup}"
        args.reply_markup = JSON.stringify args.reply_markup
    query 'editMessageText', args

exports.sendPhoto = (args) ->
    if args.caption?
        caption = ': ' + args.caption
    else
        caption = ''
    logger.outMsg "(#{args.chat_id}) <<< [#{args.photo.options?.contentType}, #{args.photo.value?.length} bytes#{caption}]"
    query 'sendPhoto', args, multipart: true

exports.forwardMessage = (args) ->
    logger.outMsg "(#{args.chat_id}) <<< [Forward: #{args.message_id}]"
    query 'forwardMessage', args
    .then (msg) ->
        msgCache.add msg
        msg

exports.sendAudio = (args) ->
    logger.outMsg "(#{args.chat_id}) <<< [Audio (#{args.audio.value?.length} bytes)]"
    query 'sendAudio', args, multipart: true

exports.sendVoice = (args) ->
    logger.outMsg "(#{args.chat_id}) <<< [Voice (#{args.voice.value?.length} bytes)]"
    query 'sendVoice', args, multipart: true    

exports.getInfo = ->
    logger.info "Getting user info..."
    query 'getMe'

exports.sendSticker = (args, fn) ->
    logger.outMsg "(#{args.chat_id}) <<< [Sticker: #{fn}]"
    query 'sendSticker', args, multipart: true

exports.answerCallbackQuery = (args) ->
    logger.outMsg "(callback answer) <<< #{args.text}"
    query 'answerCallbackQuery', args

exports.leaveChat = (args) ->
    logger.info "Leaving chat: #{args.chat_id}"
    query 'leaveChat', args
