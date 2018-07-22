BPromise = require 'bluebird'
JSONStream = require 'JSONStream'
pumpCb = require 'pump'

Server = require '../server'

command = 'ls'
pump = BPromise.promisify(pumpCb)

addCommand = (argparser) ->
  subcommand = argparser.addParser(
    command
    addHelp: true
    description: 'List all the databases on the server.'
  )

run = ({url}) ->
  pump(
    (new Server(url)).list()
    JSONStream.stringify('[', ',\n', ']\n')
    process.stdout
  )

module.exports = {addCommand, command, run}
