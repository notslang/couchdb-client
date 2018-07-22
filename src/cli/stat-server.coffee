Server = require '../server'
{handlePromisedJson} = require './util'

command = 'stat-server'

addCommand = (argparser) ->
  argparser.addParser(
    command
    addHelp: true
    description: 'Print stats for the server itself.'
  )

run = ({url}) ->
  (new Server(url)).status().then(handlePromisedJson)


module.exports = {addCommand, command, run}
