cacheMessages = {}
cacheUsers = {}

_clone = (msg) ->
    res = {}
    for k in ['message_id', 'from', 'date', 'chat', 'forward_from', 'forward_date', 'text']
        if msg[k]?
            res[k] = msg[k]
    if msg.reply_to_message?
        res.reply_to_message = _clone(msg.reply_to_message)
    res

exports.tryResolve = (msg) ->
    cached = cacheMessages[msg.message_id]
    if cached?
        for k, v of cached
            if not (k of msg)
                msg[k] = v
    msg

exports.getUserById = (userId) ->
    cacheUsers[userId]

exports.add = (msg) ->
    cacheMessages[msg.message_id] = _clone(msg)
    cacheUsers[msg.from.id] = msg.from
    if msg.forward_from?
        cacheUsers[msg.forward_from.id] = msg.forward_from

