{databaseArg, handlePromisedJson} = require './util'
CouchDB = require '../database'
existsDoc = require '../exists-doc'

command = 'exists-doc'

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Check if a document exists using HEAD.'
  )
  databaseArg(subcommand)
  subcommand.addArgument(
    'id'
    help: 'The _id of the document to check.'
    metavar: 'DOCUMENT'
  )

run = ({db, url, id}) ->
  db = new CouchDB("#{url}/#{db}")
  existsDoc(db, id).then(handlePromisedJson)

module.exports = {addCommand, command, run}
