async  = require "async"
Sender = require './sender'
Broker = require './broker'

broker = new Broker()
sender = new Sender()

require './worker_test'

innerLoop = (id, next)->
  data = "Hello: #{id}"
  sender.send 'Reverse', data, (err, data) ->
    next err

# setTimeout ->
#   for i in [1..1]
#     sender.send 'Hello', () ->
#       console.log 'hello submmited'
# , 3000

start = +new Date
#async.forEachLimit [1..100], 8, innerLoop, (err) =>
#async.forEach [1..100], innerLoop, (err) =>  

count = 2300000 

async.forEachSeries [1..count], innerLoop, (err) =>
  throw err if err?
  end = +new Date
  console.log 'Time taken:', end - start

async.forEachSeries [1..count], innerLoop, (err) =>
  throw err if err?
  end = +new Date
  console.log 'Time taken:', end - start

# setTimeout ->
#   async.forEachSeries [1..count], innerLoop, (err) =>
#     throw err if err?
#     end = +new Date
#     console.log 'Time taken:', end - start
# , 1

# setTimeout ->
#   async.forEachSeries [1..count], innerLoop, (err) =>
#     throw err if err?
#     end = +new Date
#     console.log 'Time taken:', end - start
# , 2

# setTimeout ->
#   async.forEachSeries [1..count], innerLoop, (err) =>
#     throw err if err?
#     end = +new Date
#     console.log 'Time taken:', end - start
# , 4

# setTimeout ->
#   async.forEachSeries [1..count], innerLoop, (err) =>
#     throw err if err?
#     end = +new Date
#     console.log 'Time taken:', end - start
# , 6

# setTimeout ->
#   async.forEachSeries [1..count], innerLoop, (err) =>
#     throw err if err?
#     end = +new Date
#     console.log 'Time taken:', end - start
# , 8

# setTimeout ->
#   async.forEachSeries [1..count], innerLoop, (err) =>
#     throw err if err?
#     end = +new Date
#     console.log 'Time taken:', end - start
# , 10
