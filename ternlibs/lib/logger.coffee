###
# Declare winston module
###
winston = require 'winston'
path    = require 'path'

###
# Declare config module for default values setting and change monitoring
###
Config  = require "./config"

Utils   = require './utils'

###
# Internal variables
###
internals = 
  logger      : null
  loggerInit  : (config) ->
    # Create a new logger
    transports  = []
    
    transConfig = Utils.configSnapshot config.transports

    for t, option of transConfig
      t = t.toLowerCase()
      switch t
        when 'console'
          transports.push(new (winston.transports.Console)(option))
        when 'file'
          transports.push(new (winston.transports.File)(option))
        when 'loggly'
          transports.push(new (winston.transports.Loggly)(option))
        else
          console.warn "Unsupported log transport: '#{t}'"

    # Replace the old one
    internals.logger = new winston.Logger( {'transports': transports} )

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

  # Set default configuration values
  Config.setModuleDefaults 'Logger', {
    transports:
      console:
        colorize  : true
        level     :    0
  }

  # Set config file change monitor
  Config.watch Config, 'Logger', (object, propertyName, priorValue, newValue) ->
    console.log "Logger config changed: '#{propertyName}' changed from '#{priorValue}' to '#{newValue}'"
    internals.loggerInit Config.Logger

  # Create and init. a new logger object with default settings
  internals.loggerInit Config.Logger