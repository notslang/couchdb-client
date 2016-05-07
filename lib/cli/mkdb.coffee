BPromise = require 'bluebird'

CouchDB = require '../database'

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

run = ({dbs, errorIfExists, url}) ->
  BPromise.map(dbs, (db) ->
    (new CouchDB("#{url}/#{db}")).createDatabase(errorIfExists)
  )

module.exports = {addCommand, command, run}
