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
            v = if c == 'x' then r else (r&0x3|0x8)
            v.toString(16)
    )

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
                worker.postMessage(
                    {
                        type: method
                        params: args
                        db: dbId
                        _uuid: id
                    }
                )

                processMap[id] = deferred.promise

                return deferred.promise

        handleMessage = () ->
            console.log(arguments)

        # withAllDbsEnabled: ->
        #     PouchDB.enableAllDbs = true

        getWorker: (workerScript, pouchDbScript) ->
            if worker is null and workerScript and pouchDbScript
                worker = new Worker(workerScript)
                worker.addEventListener('message', handleMessage, false)
                worker.postMessage(
                    type: 'script'
                    path: pouchDbScript
                )
                useWebWorker = true
            return worker

        closeWorker: ->
            if worker isnt null
                worker.terminate()
                worker = null
                useWebWorker = false

        create: (name, options) ->
            if useWebWorker
                id = uuid()
                dbId = uuid()
                _type = null

                worker = @getWorker()
                worker.postMessage(
                    {
                        type: 'type'
                        params: [name]
                        db: dbId
                        _uuid: id
                    }
                )

                deferred = $q.defer()
                processMap[id] = deferred.promise

                deferred.promise.then((result) ->
                    _type = result
                )

                _db =
                    _id: dbId
                    type: -> return _type

                for own method of dbMethods
                    _db[method] = workerify id, method
                _db[method] = workerify id, method

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
