Receiver = require "../lib/receiver"

# This task reverses the given string, failing randomly.
class Reverse
  run: (data, next) ->
    #if Math.random() > 0.9
    #  next "oh noes!"
    #else
    #  next null, data.split("").reverse().join("")
    next null, data.split("").reverse().join("")

receiver = new Receiver
receiver.registerWorker 'Reverse', Reverse
