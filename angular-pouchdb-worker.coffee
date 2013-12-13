# Web-worker code
ready = false
dbMap = {}


uuid = ->
    # I probably don't need a full, RFC-complaint UUID
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
            r = Math.random()*16|0
            v = if c == 'x' then r else (r&0x3|0x8)
            v.toString(16)
    )

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
    console.log(evt.data)
    if not ready and evt.data?.type? and evt.data.type isnt 'script'
        console.log('canceling')
        return

    switch evt.data.type
        when 'close' then self.close()
        when 'script'
            console.log('importing: ' + evt.data.path)
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
            console.log(evt.data)
            #throw new Error("Not Implemented")
        else
            if evt.data.type in dbMethods
                idify(evt.data.type, evt.data.params, dbMap[ext.data.db], ext.data.id)
            else
                console.log("not implemented")
                console.log(evt.data)
                #throw new Error("Not Implemented")

self.addEventListener('message', processMessage, false)
self.addEventListener('error', processError, false)
