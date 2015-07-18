if not module? and window?
    exports = window.$p = {}

class PromiseCallback
    constructor: (@func) ->
        @deferred = new Deferred()

    promise: ->
        @deferred.promise

    execute: (value) ->
        try
            retValue = @func value
            if retValue instanceof Promise
                retValue.then (realValue) =>
                    @deferred.resolve realValue
            else
                @deferred.resolve retValue
        catch err
            @deferred.reject err

exports.Promise = class Promise
    @UNRESOLVED: 0
    @RESOLVED: 1
    @REJECTED: 2

    constructor: ->
        @status = Promise.UNRESOLVED
        @value = null
        @error = null
        @callbacks = []
        @rejectCallbacks = []

    then: (func, funcElse) ->
        callback = new PromiseCallback(func)
        switch @status
            when Promise.UNRESOLVED
                @callbacks.push callback
            when Promise.RESOLVED
                @_execute callback
        @else funcElse if funcElse?
        callback.promise()

    else: (func) ->
        switch @status
            when Promise.UNRESOLVED
                @rejectCallbacks.push func
            when Promise.REJECTED
                func @error
        this

    finally: (func) ->
        @then func, func

    _resolve: (value) ->
        throw new Error("State is #{@status} - cannot resolve") unless @status == Promise.UNRESOLVED
        @status = Promise.RESOLVED
        @value = value
        callbacks = @callbacks
        @callbacks = null
        @rejectCallbacks = null
        for cb in callbacks
            @_execute cb
        return

    _execute: (cb) ->
        cb.execute @value

    _reject: (err) ->
        #throw new Error("State is #{@status} - cannot reject") unless @status == Promise.UNRESOLVED
        @status = Promise.REJECTED
        @error = err
        rejectCallbacks = @rejectCallbacks
        callbacks = null
        @rejectCallbacks = null
        if rejectCallbacks? and rejectCallbacks.length > 0
            #console.warn('what is reject callbacks?')
            for cb in rejectCallbacks
                cb @error
        else
            #console.warn('throwing up')
            throw @error
        return

exports.Deferred = class Deferred
    constructor: ->
        @promise = new Promise()

    resolve: (value) ->
        @promise._resolve value

    reject: (err) ->
        @promise._reject err

    callback: ->
        (err, value) =>
            if err?
                @reject err
            else
                @resolve value

exports.asPromise = (invocation) ->
    deferred = new Deferred()
    invocation deferred.callback()
    deferred.promise

exports.all = (promises) ->
    deferred = new Deferred()
    counter = promises.length
    results = []
    for p, i in promises
        do (i) ->
            p.then (res) ->
                counter -= 1
                results[i] = res
                if counter <= 0
                    deferred.resolve results
                return
            p.else (err) ->
                deferred.reject err
    deferred.promise

exports.resolved = (value) ->
    deferred = new Deferred()
    deferred.resolve value
    deferred.promise