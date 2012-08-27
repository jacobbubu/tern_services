module.exports = class Queue
  constructor: (@worker, @concurrency) ->
    @tasks   = []
    @workers = 0

  push: (tasks, next) ->
    tasks = [tasks] unless tasks instanceof Array
    for task in tasks
      @tasks.push data: task, next: next
      process.nextTick @_process

  _process: =>
    if @workers < @concurrency and @tasks.length > 0
      task = @tasks.shift()
      @workers += 1
      @worker task.data, =>
        @workers -= 1
        task.next.apply task, arguments if task.next?
        process.nextTick @_process
    # else
    #   process.nextTick @_process