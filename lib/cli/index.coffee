BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
find = require 'lodash/find'
from = require 'from2-array'

{ArgumentParser} = require 'argparse'

CouchDB = require '../database'
Server = require '../server'
ls = require './ls'
mkdb = require './mkdb'
packageInfo = require '../../package'

commands = [
  require './head-doc'
  require './ls'
  require './mkdb'
  require './put'
  require './query'
  require './rmdb'
  require './stat'
  require './stat-server'
]
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
subparser = argparser.addSubparsers(dest: 'command')

for command in commands
  command.addCommand(subparser)

argv = argparser.parseArgs()

(
  find(commands, command: argv.command).run(argv)
).catch((err) ->
  console.error err.message
  console.error err.stack
  process.exit(1)
)
