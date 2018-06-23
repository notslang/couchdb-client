should = require 'should'
BPromise = require 'bluebird'

CouchDB = require '../lib/database'
create = require '../lib/create'
destroy = require '../lib/destroy'
putDoc = require '../lib/put-doc'
getDoc = require '../lib/get-doc'

db = new CouchDB('http://localhost:5984/test-db')
describe 'lib/put-doc', ->
  before ->
    @timeout 10000
    create(db, replicas: 1)

  after ->
    @timeout 10000
    destroy(db)

  it 'should work', ->
    @timeout 10000
    doc = {_id: '1', content: 'something', key: 42}
    putDoc(db, doc).then(({updated, _rev, requestId}) ->
      updated.should.be.true
      _rev.should.be.a.String()
      requestId.should.be.a.String()
      return
    ).then( ->
      getDoc(db, doc._id)
    ).then((response) ->
      response.requestId.should.be.a.String()
      response.doc._rev.should.be.a.String()
      response.doc[key].should.equal(value) for key, value of doc
    )
