should = require 'should'

CouchDB = require '../lib/database'

describe 'CouchDB constructor', ->
  it 'should parse auth', ->
    db = new CouchDB('http://root:mypassword@localhost:5984/test-db')
    db.auth.should.equal 'root:mypassword'

  it 'should handle missing auth', ->
    db = new CouchDB('http://localhost:5984/test-db')
    (db.auth is null).should.be.true

  it 'should parse dbName', ->
    db = new CouchDB('http://root:mypassword@localhost:5984/test-db')
    db.dbName.should.equal 'test-db'
