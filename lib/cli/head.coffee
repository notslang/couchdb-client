BPromise = require 'bluebird'
JSONStream = require 'JSONStream'

{databaseArg, handlePromisedJson} = require './util'
CouchDB = require '../database'
headDoc = require '../head-doc'

command = 'head'

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Get 1 or more documents using HEAD.'
  )
  subcommand.addArgument(
    'db'
    help: 'The name of the database to get the doc from.'
    metavar: 'DATABASE'
  )
  subcommand.addArgument(
    'ids'
    help: 'The _ids of the documents to get the HEAD of.'
    metavar: 'DOCUMENT'
    nargs: '+'
  )

run = ({db, url, ids}) ->
  db = new CouchDB("#{url}/#{db}")
  BPromise.map(ids, (id) ->
    headDoc(db, id)
  ).then(
    handlePromisedJson
  )

module.exports = {addCommand, command, run}
