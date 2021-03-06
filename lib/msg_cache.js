// Generated by CoffeeScript 1.12.4
var FileDb, _clone, cacheCounter, cacheMessages, cacheUsers, prevCacheMessages, rotateCache;

FileDb = require('./filedb');

prevCacheMessages = {};

cacheMessages = {};

cacheUsers = {};

_clone = function(msg) {
  var i, k, len, ref, res;
  res = {};
  ref = ['message_id', 'from', 'date', 'chat', 'forward_from', 'forward_date', 'text'];
  for (i = 0, len = ref.length; i < len; i++) {
    k = ref[i];
    if (msg[k] != null) {
      res[k] = msg[k];
    }
  }
  if (msg.reply_to_message != null) {
    res.reply_to_message = _clone(msg.reply_to_message);
  }
  return res;
};

exports.tryResolve = function(msg) {
  var cached, k, v;
  cached = cacheMessages[msg.message_id];
  if (cached == null) {
    cached = prevCacheMessages[msg.message_id];
  }
  if (cached != null) {
    for (k in cached) {
      v = cached[k];
      if (!(k in msg)) {
        msg[k] = v;
      }
    }
  }
  return msg;
};

exports.getUserById = function(userId) {
  return cacheUsers[userId];
};

cacheCounter = 0;

rotateCache = function() {
  cacheCounter += 1;
  if (cacheCounter > 1000) {
    cacheCounter = 0;
    prevCacheMessages = cacheMessages;
    return cacheMessages = {};
  }
};

exports.add = function(msg) {
  rotateCache();
  cacheMessages[msg.message_id] = _clone(msg);
  cacheUsers[msg.from.id] = msg.from;
  if (msg.forward_from != null) {
    cacheUsers[msg.forward_from.id] = msg.forward_from;
  }
  return FileDb.get('last_timestamp').update(function(data) {
    var base, chatId, fromId;
    chatId = msg.chat.id;
    fromId = msg.from.id;
    if (data[chatId] == null) {
      data[chatId] = {};
    }
    if ((base = data[chatId])[fromId] == null) {
      base[fromId] = {};
    }
    data[chatId][fromId].prev = data[chatId][fromId].last;
    return data[chatId][fromId].last = msg.date;
  });
};
