config = require '../lib/config'

module.exports =
    name: 'Welcome'
    pattern: /!(welcome|intro)$/

    isAcceptMsg: (msg) ->
        msg.new_chat_participant? or @isSudo(msg) and @matchPattern(msg, msg.text)

    onMsg: (msg) ->
        if not msg.new_chat_participant?
            if msg.text == '!welcome'
                @welcomeUser msg, msg.from
            else
                @intro msg
        else
            #legitimate!
            user = msg.new_chat_participant
            if user.username == config.userName
                #console.log "$$$$ #{user.username} $$$$"
                @intro msg
            else
                if user.username? and user.username.endsWith('bot')
                    return
                @welcomeUser msg, user

    intro: (msg) ->
        msg.send "Всем привет! Я очень умная, и могу делать много разных вещей. Введите /help, чтобы посмотреть список команд."

    welcomeUser: (msg, user) ->
        msg.send "Добро пожаловать, #{user.first_name}!"