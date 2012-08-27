###
# Declare winston module
###
winston       = require 'winston'
BrokersHelper = require('tern.central_config').BrokersHelper

###
# Internal variables
###
internals = 
  logger      : null
  configObj   : null
  config      : null
  
  loggerInit:  ->    
    transports  = []
    
    for t, option of internals.config
      t = t.toLowerCase()
      switch t
        when 'console'
          transports.push(new (winston.transports.Console)(option))
        when 'file'
          transports.push(new (winston.transports.File)(option))
        when 'loggly'
          transports.push(new (winston.transports.Loggly)(option))
        else
          console.error "Unsupported log transport: '#{t}'"

    # Replace the old one
    internals.logger = new winston.Logger( {'transports': transports} )

    internals.logger.emit = 

    # We use syslog levels:
    #   debug: 0,
    #   info: 1,
    #   notice: 2,
    #   warning: 3,
    #   error: 4,
    #   crit: 5,
    #   alert: 6,
    #   emerg: 7
    internals.logger.setLevels winston.config.syslog.levels
    #internals.logger.addColors winston.config.syslog.colors

    # Exports log methods (debug, info ...)
    setMethod = (method) ->
      name = method
      exports[name] = ->
        return internals.logger[name].apply(internals.logger, arguments)

    for method of winston.config.syslog.levels
      setMethod method

###
# Initialization
###
initialize = do ->

  internals.configObj = BrokersHelper.getConfig('logger/transports')

  if internals.configObj?

    internals.config = internals.configObj.value
    
    internals.configObj.on 'changed', (oldValue, newValue) ->
      console.log 'logger config changed'
      internals.config = newValue
      internals.loggerInit()

  else
    internals.config = 
      console:
        colorize  : true
        level     :    0

  internals.loggerInit()