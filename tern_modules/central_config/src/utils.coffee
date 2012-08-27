deepEquals = (obj1, obj2) ->
  #we do this because two objects may have the same data fields and data but different prototypes
  x1 = JSON.parse JSON.stringify(obj1)
  x2 = JSON.parse JSON.stringify(obj2)

  if typeof(x1) in ['string', 'number'] and typeof(x2) in ['string', 'number']
    return x1 is x2

  p = null
  for p of x1
    return false if typeof (x2[p]) is 'undefined'
  for p of x1
    if x1[p]
      switch typeof x1[p]
        when 'object'
          return false unless deepEquals x1[p], x2[p]
        when 'function'
          return false if typeof (x2[p]) is 'undefined' or (p isnt 'equals' and x1[p].toString() isnt x2[p].toString())
        else
          return false unless x1[p] is x2[p]
    else
      return false if x2[p]
  for p of x2
    return false if typeof (x1[p]) is 'undefined'
  true

module.exports.deepEquals = deepEquals