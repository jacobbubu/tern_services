Sender = require './sender'
Broker = require './broker'

broker = new Broker()
sender = new Sender()

require './worker_test'
