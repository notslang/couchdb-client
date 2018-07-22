{databaseArg, handlePromisedJson} = require './util'
CouchDB = require '../database'
removeDoc = require '../remove-doc'

command = 'rm-doc'

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Remove a document using DELETE.'
  )
  databaseArg(subcommand)
  subcommand.addArgument(
    'id'
    help: 'The _id of the document to remove.'
    metavar: 'DOCUMENT'
  )
  subcommand.addArgument(
    '_rev'
    help: 'The _rev of the document to remove.'
    metavar: 'REVISION'
  )

run = ({db, url, id, _rev}) ->
  db = new CouchDB("#{url}/#{db}")
  removeDoc(db, id, _rev).then(handlePromisedJson)

module.exports = {addCommand, command, run}
