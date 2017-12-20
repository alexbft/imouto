logger = require 'winston'
misc = require './misc'

SAVE_DELAY_MS = 10000

db = {}
delays = {'last_timestamp': 300000}

module.exports = class FileDb
  @get: (name) ->
    if name not of db
      db[name] = new FileDb name
      db[name].init()
    db[name]

  constructor: (@name) ->
    @saveDelay = delays[@name] ? SAVE_DELAY_MS
    @_timer = null
    @_storage = {}
    @_initialized = false

  init: ->
    if not @_initialized
      logger.debug "Initializing FileDB: #{@name}"
      @_storage = misc.loadJson(@name) ? {}
      @_initialized = true
    return

  get: -> @_storage

  update: (fn) ->
    fn @_storage
    @save()

  save: ->
    if @_timer != null
      return
    @_timer = setTimeout =>
      logger.debug "Saving FileDB: #{@name}"
      misc.saveJson @name, @_storage
      @_timer = null
    , @saveDelay
    return
