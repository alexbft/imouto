logger = require 'winston'

msgCache = require './msg_cache'
query = require './query'

exports.sendMessage = (args) ->
    logger.outMsg "(#{args.chat_id}) <<< #{args.text}"
    query 'sendMessage', args

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

exports.getInfo = ->
    logger.info "Getting user info..."
    query 'getMe'