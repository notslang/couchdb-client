BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
pumpCb = require 'pump'

{databaseArg} = require './util'
CouchDB = require '../database'

command = 'query'
pump = BPromise.promisify(pumpCb)

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    help: ''
  )
  databaseArg(subcommand)
  subcommand.addArgument(
    'design'
    help: 'The design document to query.'
    metavar: 'DESIGN'
    nargs: '?'
    type: 'string'
  )
  subcommand.addArgument(
    'view'
    help: 'The view to query.'
    metavar: 'VIEW'
    nargs: '?'
    type: 'string'
  )
  subcommand.addArgument(
    ['--reduce']
    action: 'storeTrue'
    help: ''
  )
  subcommand.addArgument(
    ['--include-docs']
    action: 'storeTrue'
    dest: 'includeDocs'
    help: 'Automatically fetch and include the document which emitted each view
    entry.'
  )
  subcommand.addArgument(
    ['--group-level']
    dest: 'groupLevel'
    help: 'Define how many items of the key array are used in grouping during
    the map-reduce function.'
    metavar: 'LEVEL'
    type: 'int'
  )
  subcommand.addArgument(
    ['--limit']
    help: 'Limit the number of documents in the output.'
    type: 'int'
  )
  subcommand.addArgument(
    ['--startkey']
    help: ''
    metavar: 'KEY'
    type: 'string'
  )
  subcommand.addArgument(
    ['--endkey']
    help: ''
    metavar: 'KEY'
    type: 'string'
  )

run = (args) ->
  server = "#{args.url}/#{args.db}"
  delete args.url
  delete args.db
  pump(
    (new CouchDB(server)).query(args)
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

module.exports = {addCommand, command, run}
