logger = require 'winston'

misc = require '../lib/misc'

BOARD = 'b'
HOST = '2ch.hk'

isButthurt = (comment) ->
  comment.indexOf('<br>@<br>') != -1

isButthurtThread = (comment) ->
  isButthurt(comment) or comment.toLowerCase().indexOf('бугурт') != -1

isGoodThread = (thread) ->
  thread.posts_count >= 50 and not thread.banned and not thread.closed

isGoodPost = (post) ->
  fixText(post.comment).trim().length >= 50

randomThread = (anyPost) ->
  misc
  .getAsCloud "https://#{HOST}/#{BOARD}/catalog.json"
  .then (data) ->
    data = JSON.parse data
    misc.randomChoice data.threads.filter (thread) -> isGoodThread(thread) and (anyPost or isButthurtThread thread.comment)

randomPost = (id, anyPost) ->
  misc
  .getAsCloud "https://#{HOST}/#{BOARD}/res/#{id}.json"
  .then (data) ->
    data = JSON.parse data
    misc.randomChoice data.threads[0].posts.filter (post) -> if anyPost then isGoodPost post else isButthurt post.comment

fixText = (text) ->
  text = text
  .replace /\<br\>/g, '\n'
  .replace /\<span class="(.*?)"\>(.*?)\<\/span\>/g, '$2'
  .replace /\<a.*?\<\/a\>/g, ''
  if text.length > 1500
    text = text.substr 0, 1500
  text

getPostText = (post) ->
  text = fixText(post.comment).trim()
  if post.files.length > 0 and post.files[0].nsfw == 0
    text += "\n\nhttps://#{HOST}/#{BOARD}/#{post.files[0].path}"
  text

module.exports =
  name: 'Butthurt thread'
  
  isPrivileged: true
  warnPrivileged: false  

  pattern: /!(кек|сас|kek|sas)/

  onMsg: (msg, safe) ->
    isSas = msg.match[1].toLowerCase() in ['сас', 'sas']
    safe randomThread isSas
    .then (thread) ->
      if not thread?
        msg.reply 'В Багдаде всё спокойно!'
      else
        safe randomPost thread.num, isSas
        .then (post) ->
          if not post?
            msg.reply 'В Багдаде всё спокойно!'
          else
            msg.send getPostText(post), parseMode: 'HTML'

  isSudo: (msg) ->
    msg.chat.type == 'private' or @bot.isSudo(msg)
  
  onError: (msg) ->
    msg.reply 'ты сас'
