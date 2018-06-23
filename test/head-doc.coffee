should = require 'should'
BPromise = require 'bluebird'

CouchDB = require '../lib/database'
create = require '../lib/create'
destroy = require '../lib/destroy'
putDoc = require '../lib/put-doc'
headDoc = require '../lib/head-doc'

db = new CouchDB('http://localhost:5984/test-db')
describe 'lib/head-doc', ->
  doc = {_id: '1', content: 'something', key: 42}

  before ->
    @timeout 10000
    create(db, replicas: 1).then( ->
      putDoc(db, doc)
    )

  after ->
    @timeout 10000
    destroy(db)

  it 'should work', ->
    @timeout 10000

    headDoc(db, doc._id).then((response) ->
      response.status.should.equal(200)
      response.requestId.should.be.a.String()
    )
