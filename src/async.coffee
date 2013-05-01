#!/usr/bin/env coffee
#
# Copyright 2013 Artillery Games, Inc. All rights reserved.
#
# This code, and all derivative work, is the exclusive property of Artillery
# Games, Inc. and may not be used without Artillery Games, Inc.'s authorization.
#
# Author: Ian Langworth

exports.serial = (steps, finalCallback) ->
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
