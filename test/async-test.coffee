#!/usr/bin/env coffee
#
# Copyright 2013 Artillery Games, Inc. All rights reserved.
#
# This code, and all derivative work, is the exclusive property of Artillery
# Games, Inc. and may not be used without Artillery Games, Inc.'s authorization
#
# Author: Ian Langworth

async = require '../lib/async'

exports.testSerial =

  # Test that serial() runs things serially.
  testBasic: (test) ->
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
  testEmpty: (test) ->
    result = []
    async.serial [], (err) ->
      test.equal err, null
      test.deepEqual result, []
      test.done()


  # Test that passing an error to the callback short-circuits.
  testError: (test) ->
    result = []
    async.serial [
      (cb) ->
        result.push 'A'
        cb()
      (cb) ->
        result.push 'B'
        cb 'Some error'
      (cb) ->
        test.ok false, 'Should not execute'
    ], (err) ->
      test.equal err, 'Some error'
      test.deepEqual result, ['A', 'B'] # No 'C'
      test.done()

  # Test passing values to each subsequent callback.
  testWaterfall: (test) ->
    async.serial [
      (cb) ->
        cb null, 11
      (x, cb) ->
        test.equal x, 11
        cb null, 22, 33
      (y, z, cb) ->
        test.equal y, 22
        test.equal z, 33
        cb null, 44, 55
    ], (err, q, r) ->
      test.equal err, null, 'No error'
      test.equal q, 44, 'Final arg 1'
      test.equal r, 55, 'Final arg 2'
      test.done()

  # Test that an error while passing values doesn't pass a value.
  testWaterfallError: (test) ->
    async.serial [
      (cb) ->
        cb null, 111
      (value, cb) ->
        test.equal value, 111
        cb 'Some error', 222
      (value, cb) ->
        test.ok false, 'Should not execute'
    ], (err, value) ->
      test.equal err, 'Some error'
      test.equal value, undefined
      test.done()

