#!/usr/bin/env coffee
#
# Copyright 2013 Artillery Games, Inc. All rights reserved.
#
# This code, and all derivative work, is the exclusive property of Artillery
# Games, Inc. and may not be used without Artillery Games, Inc.'s authorization
#
# Author: Ian Langworth

async = require '../lib/async'


# Test that serial() runs things serially.
exports.testSerialBasic = (test) ->
  result = []
  async.serial [
    (cb) ->
      result.push 'A'
      cb()
    (cb) ->
      result.push 'B'
      cb null # Should be the same as undefined.
    (cb) ->
      result.push 'C'
      cb()
  ], (err) ->
    test.equal err, null
    test.deepEqual result, ['A', 'B', 'C']
    test.done()


# Test that the serial handles an empty list and still calls the final callback.
exports.testSerialEmpty = (test) ->
  result = []
  async.serial [], (err) ->
    test.equal err, null
    test.deepEqual result, []
    test.done()


# Test that passing an error to the callback short-circuits.
exports.testSerialError = (test) ->
  result = []
  async.serial [
    (cb) ->
      result.push 'A'
      cb()
    (cb) ->
      result.push 'B'
      cb 'Some error'
    (cb) ->
      result.push 'C'
      cb()
  ], (err) ->
    test.equal err, 'Some error'
    test.deepEqual result, ['A', 'B'] # No 'C'
    test.done()
