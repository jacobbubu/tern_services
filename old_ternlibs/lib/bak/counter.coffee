pad = (value, length) ->
  padArray = ['', '0', '00', '000', '0000', '00000', '000000']
  strValue = value.toString()
  return padArray[length - strValue.length] + strValue

class Counter
  
  @_startDate = +(new Date('2012-01-01Z'))
  @_pid = pad(process.pid, 5)
  @counterToDate: (counter) ->
    datePart = +counter.slice(0, 11) + Counter._startDate
    return new Date(datePart)

  constructor: () ->
    @lastMSec = 0
    @counterInMSec = 0
    return

  next: ->
    currentMSec = +(new Date) - Counter._startDate

    if currentMSec is @lastMSec
      @counterInMSec++
    else 
      @lastMSec = currentMSec
      @counterInMSec = 0

    return @lastMSec.toString() + Counter._pid  + pad(@counterInMSec, 3)

module.exports = Counter
