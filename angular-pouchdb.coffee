dbMethods = {
    put: true
    post: true
    get: true
    remove: true
    bulkDocs: true
    allDocs: true
    putAttachment: true
    getAttachment: true
    removeAttachment: true
    query: true
    info: true
    compact: true
    revsDiff: true
    changes: true
}

uuid = ->
    # I probably don't need a full, RFC-complaint UUID
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
            r = Math.random()*16|0
            v = c == 'x' ? r : (r&0x3|0x8)
            v.toString(16)
    )

if window.document isnt undefined
    useWebWorker = false

    angular.module('pouchdb', ['ng'])

    .provider 'pouchdb', ->
        $get: ($q, $rootScope, $timeout) ->
            processMap = {}
            worker = null

            qify = (fn) ->
                () ->
                    callback = (err, res) ->
                        $timeout ->
                            $rootScope.$apply ->
                                if (err)
                                    deferred.reject err
                                else
                                    deferred.resolve res
                    deferred = $q.defer()
                    args = if arguments? then Array.prototype.slice.call(arguments) else []
                    args.push callback
                    fn.apply this, args
                    deferred.promise

            workerify = (dbId, method) ->
                ->
                    id = uuid()
                    deferred = $q.defer()

                    args = if arguments? then Array.prototype.slice.call(arguments) else []
                    self.postMessage(
                        type: method
                        params: args
                        db: dbId
                        _uuid: id
                    )

                    processMap[id] = deferred.promise

                    return deferred.promise

            useWebWorker: (onoff) ->
                if onoff in [true, false]
                    if onoff isnt useWebWorker
                        if useWebWorker is true and worker isnt null
                            worker.close()
                            worker = null
                        else
                            worker = new Worker('angular-pouchdb.js')

                    useWebWorker = onoff

                return useWebWorker

            # withAllDbsEnabled: ->
            #     PouchDB.enableAllDbs = true

            create: (name, options) ->
                if useWebWorker
                    id = uuid()
                    _db =
                        id: id

                    for own method of dbMethods
                        _db[method] = workify id, method

                else
                    db = new PouchDB(name, options)

                    _db =
                        changes: (options) ->
                            clone = angular.copy options
                            clone.onChange = (change) ->
                                $timeout ->
                                    $rootScope.$apply ->
                                        options.onChange change
                            db.changes clone
                        type: db.type

                    for own method of dbMethods
                        _db[method] = qify db[method]

                return _db

            allDbs: qify PouchDB.allDbs
            destroy: qify PouchDB.destroy
            replicate: PouchDB.replicate

else
    # Web-worker code
    ready = false
    dbMap = {}

    getUuid = ->
        id = uuid()
        while id in dbMap
            id = uuid()
        return id

    idify = (method, params, scope=PouchDB, id=null) ->
        if id is null
            id = getUuid()

        callback = (err, res) ->
            self.postMessage(
                err: err
                res: res
                id: id
            )

        args = params
        args.push callback
        scope[method].apply(scope, args)
        return id

    processError = (evt) ->
        self.postMessage type: 'error', data: evt

    processMessage = (evt) ->
        if not ready and evt.data?.type? isnt 'script'
            return

        switch evt.data.type
            when 'close' then self.close()
            when 'script'
                importScripts(evt.data.path)
                ready = true
                self.postMessage('ready')
            when 'db'
                dbMap[evt.data.db] = PouchDB(evt.data.name, evt.data.params, PouchDB)
            when 'destroy'
                idify('destroy', evt.data.params, PouchDB, evt.data.id)
            when 'allDbs'
                idify('allDbs', evt.data.params, PouchDB, evt.data.id)
            when 'replicate'
                    throw new Error("Not Implemented")
            else
                if evt.data.type in dbMethods
                    idify(evt.data.type, evt.data.params, dbMap[ext.data.db], ext.data.id)
                else
                    throw new Error("Not Implemented")

    self.addEventListener('message', processMessage, false)
    self.addEventListener('error', processError, false)
