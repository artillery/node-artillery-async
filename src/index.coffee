#!/usr/bin/env coffee

exports.barrier = (count, finalCallback) ->
  return finalCallback() if count == 0
  return ->
    count--
    finalCallback() if count == 0

exports.series = (steps, finalCallback) ->
  index = 0

  processNextStep = (lastArgs = []) ->
    if not steps[index]?
      finalArgs = [null].concat(lastArgs) # (err, arg1, arg2, ...)
      finalCallback?.apply null, finalArgs
      return

    callback = (err, args...) ->
      if err?
        finalCallback? err
      else
        processNextStep args
      return

    nextArgs = lastArgs.concat(callback) # (arg1, arg2, ..., cb)
    steps[index++].apply null, nextArgs
    return

  processNextStep()
  return

exports.parallel = (steps, finalCallback) ->
  if steps.length == 0
    finalCallback? null
    return

  errors = []
  count = steps.length
  barrier = (err) ->
    if err? and count >= 0
      count = -1
      finalCallback? err
    else
      count--
      if count == 0
        finalCallback? null
    return

  for step in steps
    step barrier

  return

exports.while = (condition, iterator, finalCallback) ->
  process = ->
    if not condition()
      finalCallback? null
      return
    callback = (err) ->
      if err?
        finalCallback? err
      else
        process()
      return
    iterator callback
    return

  process()
  return

exports.forEachSeries = (array, iterator, finalCallback) ->
  index = 0
  length = array.length
  condition = ->
    return index < length
  arrayIterator = (cb) ->
    iterator array[index++], cb
    return
  exports.while condition, arrayIterator, finalCallback
  return

exports.forEachParallel = (array, iterator, limit, finalCallback) ->
  if not finalCallback?
    finalCallback = limit
    limit = Infinity
  return finalCallback(null) unless array.length

  errors = []
  inFlight = index = 0

  done = (err) ->
    errors.push err if err
    inFlight--
    if inFlight == 0 and index >= array.length
      finalCallback(if errors.length then errors else null)
    else
      next()

  next = ->
    while inFlight < limit and index < array.length
      inFlight++
      iterator array[index++], done

  next()
  return
