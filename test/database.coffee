BPromise = require 'bluebird'
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

  it 'should set a default sessionTimeout', ->
    db = new CouchDB('http://root:mypassword@localhost:5984/test-db')
    db.sessionTimeout.should.equal 600000

  it 'should accept sessionTimeout values', ->
    value = 1234567
    db = new CouchDB(
      'http://root:mypassword@localhost:5984/test-db'
      sessionTimeout: value
    )
    db.sessionTimeout.should.equal value
