BPromise = require 'bluebird'
JSONStream = require 'JSONStream'

{databaseArg, handlePromisedJson} = require './util'
CouchDB = require '../database'
getDoc = require '../get-doc'

command = 'get-doc'

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Get a document using GET.'
  )
  databaseArg(subcommand)
  subcommand.addArgument(
    'id'
    help: 'The _id of the document to get.'
    metavar: 'DOCUMENT'
  )
  subcommand.addArgument(
    '_rev'
    help: 'The _rev of the document to get.'
    metavar: 'REVISION'
    nargs: '?'
  )

run = ({db, url, id, _rev}) ->
  db = new CouchDB("#{url}/#{db}")
  getDoc(db, id, {_rev}).then(handlePromisedJson)

module.exports = {addCommand, command, run}
