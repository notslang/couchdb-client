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

handlePromisedJson = (res) ->
  console.log(JSON.stringify(res, null, 2))

humanReadableArg = (parser) ->
  parser.addArgument(
    ['-b', '--bytes']
    action: 'storeTrue'
    defaultValue: false
    help: 'Print sizes in bytes, rather than human readable formats'
  )

module.exports = {
  databaseArg
  databaseListArg
  handlePromisedJson
  humanReadableArg
}
