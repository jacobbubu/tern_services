util = require('util')

RequestSender = require './request_sender'

key_iv =
  key: "8eb5575e940893ebd78c8df499e6541f"
  iv:  "1f07c9e9866d53cf5f1005464fc8f474"

sender = new RequestSender('tcp://127.0.0.1:3001', key_iv, 600 * 1000)

console.log "COMMAND: run 1000, clear, mem, /quit"

process.stdin.resume()
process.stdin.setEncoding('utf8')

process.stdin.on 'data',  (chunk) ->
  chunk = chunk.replace(/\s+$/, '')
  args = chunk.split /\s+/
  switch args[0]
    when '/quit'
      process.exit()
    when 'echo'
      console.log 'Hi, there!'
    when 'mem'
      console.log util.inspect( process.memoryUsage() )
    when 'clear'
      console.log """\033[2J"""
    when 'run'
      args[1] = args[1] ? 1000
      runTest(+args[1])

runTest  = (count) ->
  msg =
    data: """
Recovering from a multi-node cluster failure caused by OOM on ...
mail-archives.apache.org/.../%3C4E2F762C.2040... - 网页快照 - 翻译此页
27 Jul 2011 – The major compaction followed by a manual GC allows us to keep the disk usage low on each node. The manual GC is necessary as the ...
[Cassandra-user] Fwd: Cassandra Memory Trend - increased ...
grokbase.com/.../cassandra-memory-trend-increas... - 网页快照 - 翻译此页
19 Aug 2011 – I started the node at 14:05, at 15:05 I did a manual GC. At 14:05, the node was GC'ed and reflected a 22MB memory footprint. At 15:05 the ...
Troubleshooting Guide | DataStax Cassandra 0.8 Documentation
www.datastax.com/docs/0.8/.../index - 网页快照 - 翻译此页
Nodes seem to freeze after some period of time¶ ... decide to swap out some portion of the JVM that isn't in use, but eventually the JVM will try to GC this space.
How to prevent memory leaks in node.js? - Stack Overflow
stackoverflow.com/.../how-to-prevent-memory-le... - 网页快照 - 翻译此页
4 个回答 - 2011年4月20日
As far as I know the V8 engine doesn't do any garbage collection. ... any implementation of a language where manual memory management is ...
获得更多知识搜索结果

Quantifying the Performance of Garbage Collection vs. Explicit ...
lambda-the-ultimate.org › forums › LtU Forum - 网页快照 - 翻译此页
20 个帖子 - 12 个作者 - 2007年12月3日
I think the real culprit behind the "poor performance" of GC languages is .... the costs of manual and automatic memory management all else being equal. .... children of 
    """

  for i in [1..count]
    msg.c = i
    sender.send msg, (err, response) ->
      if err?
        console.log err      
      else  
        console.dir response.body.c
