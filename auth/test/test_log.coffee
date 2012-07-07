colors      = require 'colors'

colors.setTheme {
  silly: 'rainbow',
  input: 'grey',
  verbose: 'cyan',
  prompt: 'grey',
  info: 'green',
  data: 'grey',
  help: 'cyan',
  warn: 'yellow',
  debug: 'blue',
  error: 'red'
}

formatClientMessage = (message) ->
  message = message.trim()
  message = "\r\nClient: " + message
  message = message.replace /\r\n/g, "\r\n\t\t"

exports.clientLog = (messages...) ->
  message = messages.join " "
  console.log formatClientMessage(message).help

exports.clientError = (messages...) ->
  message = messages.join " "
  console.log formatClientMessage(message).error

formatServerMessage = (message) ->
  message = message.trim()
  message = "\r\nServer: " + message
  message = message.replace /\r\n/g, "\r\n\t\t"

exports.serverLog = (messages...) ->
  message = messages.join " "
  console.log formatServerMessage(message).input

exports.serverError = (messages...) ->
  message = messages.join " "
  console.log formatServerMessage(message).warn