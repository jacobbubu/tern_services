
process.title = 'A Lot of Timers'
cb = (count) ->
  setTimeout ->
    #console.log count
    cb count
  ,
  500

for i in [1..10000]
  cb i
