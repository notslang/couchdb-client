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
    description: 'Check a document using HEAD.'
  )
  subcommand.addArgument(
    'db'
    help: 'The name of the database to get the doc from.'
    metavar: 'DATABASE'
  )
  subcommand.addArgument(
    'id'
    help: 'The _id of the document to check.'
    metavar: 'DOCUMENT'
  )

run = ({db, url, id}) ->
  db = new CouchDB("#{url}/#{db}")
  headDoc(db, id).then(handlePromisedJson)

module.exports = {addCommand, command, run}
