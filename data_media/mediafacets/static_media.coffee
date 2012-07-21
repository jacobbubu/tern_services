send_media = require './send_media'

exports = module.exports = (options) ->
  options = options ? {}

  return (req, res, next) ->
    next unless req.method in ['GET', 'HEAD']

    error = (err) ->
      if err.status is 404
        next()
      else
        next err

    send_media(req)
      .maxage(options.maxAge ? 0)
      .on('error', error)
      .pipe(res)