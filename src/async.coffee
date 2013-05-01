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

  processNextStep = ->
    if not steps[index]?
      return finalCallback?(null)

    steps[index++] (err) ->
      if err?
        return finalCallback?(err)
      else
        processNextStep()

  processNextStep()
