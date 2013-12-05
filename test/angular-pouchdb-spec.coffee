describe('angular-pouchdb', () ->
    beforeEach(module('pouchdb'))

    it("should be able to create a pouchdb database", inject((pouchdb, $rootScope) ->
        docId = '' + Math.random()
        db = pouchdb.create(docId)
        orig = new PouchDB(docId)

        expect(db.type()).toBe(orig.type())
    ))

    it("should be able to create a document", inject((pouchdb, $rootScope, $timeout) ->
        db = pouchdb.create('test')
        orig = new PouchDB('test')
        docId = '' + Math.random()
        doc = null
        rev = null

        runs(->
            promise = db.put({_id: docId, name: 'Bob'})

            promise.then(
                (output) ->
                    expect(output.ok).toBe(true)
                    expect(output.id).toBe(docId)
                    rev = output.rev
                (err) ->
                    expect(err).toBeUndefined()
            )
        )

        waitsFor(
            ->
                try
                    $timeout.flush()
                catch e

                rev isnt null
            "db.put to complete."
            2000
        )

        runs(->
            orig.get(docId, (err, doc) ->
                if err
                    expect(err).toBeUndefined()
                else
                    expect(doc._id).toBe(docId)
                    expect(doc._rev).toBe(rev)
                    expect(doc.name).toBe('Bob')
                    rev = null
            )
        )

        waitsFor(
            -> rev is null
            "orig.get to complete"
            2000
        )

        runs(-> expect(true).toBe(true) )
    ))
)
