Sender = require '../lib/sender'

sender = new Sender()

totalCount = 2000
count = 0

# 'Reverse' is a system worker for testing purpose
for i in [0...totalCount]
  data = "Hello: #{i}"
  handle = sender.send 'Reverse', data

  handle.on "submit", =>
    console.log "Submitted: %s", handle.id

  handle.on "complete", (data) =>
    count++
    console.log "Completed: %s (%s)", handle.id, data
    if count is totalCount
      console.log 'Total count:', count

  handle.on "error", (error) =>
    count++
    console.error "Failed: %s (%s)", handle.id, error
    if count is totalCount
      console.log 'Total count:', count

###
async.forEach [1..count], innerLoop, (err) =>
  throw err if err?
  end = +new Date
  console.log 'Time taken:', end - start
###
