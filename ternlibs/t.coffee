Counter = require "./lib/counter"

mc1 = new Counter()
mc2 = new Counter()
start = +new Date
for i in [1..100]
  console.log 'mc1: ' + mc1.next()
  console.log 'mc2: ' + mc2.next()

console.log ((+new Date) - start).toString(), 'ms'

console.log +Counter.counterToDate('1262501842955884000')