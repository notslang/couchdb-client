BPromise = require 'bluebird'

CouchDB = require '../database'
create = require '../create'

command = 'mkdb'

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'Create one or more databases.'
  )
  subcommand.addArgument(
    'dbs'
    help: 'The name(s) of the database(s) to create.'
    metavar: 'DATABASE'
    nargs: '+'
  )
  subcommand.addArgument(
    ['--error-if-exists']
    action: 'storeTrue'
    dest: 'errorIfExists'
    help: 'Don\'t ignore the database already existing.'
  )
  subcommand.addArgument(
    ['--replicas']
    type: 'int'
    dest: 'replicas'
    help: 'Number of copies there are of every document.'
  )
  subcommand.addArgument(
    ['--shards']
    type: 'int'
    dest: 'shards'
    help: 'Number of shards.'
  )

run = ({dbs, url, errorIfExists, replicas, shards}) ->
  BPromise.map(dbs, (dbName) ->
    db = new CouchDB("#{url}/#{dbName}")
    create(db, {errorIfExists, replicas, shards})
  )

module.exports = {addCommand, command, run}
