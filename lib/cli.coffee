{ArgumentParser} = require 'argparse'
BPromise = require 'bluebird'
from = require 'from2-array'
JSONStream = require 'JSONStream'
map = require 'through2'
pumpCb = require 'pump'

packageInfo = require '../package'
CouchDB = require './database'
Server = require './server'

pump = BPromise.promisify(pumpCb)

databaseArg = (parser, required = true) ->
  parser.addArgument(
    ['-d', '--database']
    dest: 'db'
    help: 'The name of the database to use.'
    required: required
  )

databaseListArg = (parser) ->
  parser.addArgument(
    ['-d', '--database']
    action: 'append'
    dest: 'dbs'
    help: 'The name(s) of the database(s) to use. If omitted, all databases will
    be used.'
  )

humanReadableArg = (parser) ->
  parser.addArgument(
    ['-b', '--bytes']
    action: 'storeTrue'
    help: 'Print sizes in bytes, rather than human readable formats'
    defaultValue: false
  )

argparser = new ArgumentParser(
  addHelp: true
  description: packageInfo.description
  version: packageInfo.version
)

argparser.addArgument(
  ['--url']
  help: 'The URL of the CouchDB server to connect to. If you need to connect
  with authentication, you should specify it in the URL using the format
  http://username:password@localhost:5984. Defaults to http://localhost:5984.'
  defaultValue: 'http://localhost:5984'
)

subparsers = argparser.addSubparsers(dest: 'command')

subcommand = subparsers.addParser(
  'ls'
  description: 'List all the databases on the server.'
  addHelp: true
)

subcommand = subparsers.addParser(
  'mkdb'
  description: 'Create one or more databases.'
  addHelp: true
)
subcommand.addArgument(
  'dbs'
  metavar: 'DATABASE'
  nargs: '+'
  help: 'The name(s) of the database(s) to create.'
)
subcommand.addArgument(
  ['--error-if-exists']
  action: 'storeTrue'
  dest: 'errorIfExists'
  help: 'Don\'t ignore the database already existing.'
)

subcommand = subparsers.addParser(
  'put'
  description: 'Reads JSON documents from STDIN and put them in the database'
  addHelp: true
)
databaseArg(subcommand)

subcommand = subparsers.addParser(
  'query'
  addHelp: true
)
databaseArg(subcommand)
subcommand.addArgument(
  'design'
  metavar: 'DESIGN'
  help: 'The design document to query.'
  nargs: '?'
  type: 'string'
)
subcommand.addArgument(
  'view'
  metavar: 'VIEW'
  help: 'The view to query.'
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
  metavar: 'LEVEL'
  dest: 'groupLevel'
  help: 'Define how many items of the key array are used in grouping during the
  map-reduce function.'
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

subcommand = subparsers.addParser(
  'stat-server'
  description: 'Print stats for the server itself.'
  addHelp: true
)

subcommand = subparsers.addParser(
  'stat'
  description: 'Print stats for each database.'
  addHelp: true
)
humanReadableArg(subcommand)
databaseListArg(subcommand)

handlePromisedJson = (res) ->
  console.log(JSON.stringify(res, null, 2))

ls = ({url}) ->
  pump(
    (new Server(url)).list()
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

mkdb = ({dbs, errorIfExists, url}) ->
  BPromise.map(dbs, (db) ->
    (new CouchDB("#{url}/#{db}")).createDatabase(errorIfExists)
  )

put = ({dbs, url}) ->
  BPromise.map(dbs, (db) ->
    (new CouchDB("#{url}/#{db}")).createDatabase()
  )

query = (args) ->
  server = "#{args.url}/#{args.db}"
  delete args.url
  delete args.db
  pump(
    (new CouchDB(server)).query(args)
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

statServer = ({url}) ->
  (new Server(url)).status().then(handlePromisedJson)

stat = ({dbs, url}) ->
  dbs = (
    if dbs is null
      (new Server(url)).list()
    else
      from(dbs)
  )
  pump(
    dbs
    map(objectMode: true, (db, enc, cb) ->
      (new CouchDB("#{url}/#{db}")).status().then((res) -> cb(null, res))
    )
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

commandMap =
  'ls': ls
  'mkdb': mkdb
  'put': put
  'query': query
  'stat-server': statServer
  'stat': stat

argv = argparser.parseArgs()

(
  commandMap[argv.command](argv)
).catch((err) ->
  console.error err.message
  console.error err.stack
  process.exit(1)
)
