#!/usr/bin/env coffee

async = if process.env.ARTILLERY_ASYNC_COVERAGE then require '../lib-cov/index' else require '../lib/index'

defer = (fn) -> setTimeout fn, 0 # setImmediate not in Node v0.8

exports.testBarrier =

  # Test that a basic barrier works.
  testBasic: (test) ->
    test.expect 0
    barrier = async.barrier 3, ->
      test.done()
    defer barrier
    defer barrier
    defer barrier

  # Test that a barrier of size 0 works.
  testBarrierZero: (test) ->
    test.expect 0
    barrier = async.barrier 0, ->
      test.done()

exports.testSeries =

  # Test that series() runs things serially.
  testBasic: (test) ->
    test.expect 2
    result = []
    async.series [
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

  # Test that the series handles an empty list and still calls the final callback.
  testEmpty: (test) ->
    test.expect 2
    result = []
    async.series [], (err) ->
      test.equal err, null
      test.deepEqual result, []
      test.done()

  # Test that passing an error to the callback short-circuits.
  testError: (test) ->
    test.expect 2
    result = []
    async.series [
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
    test.expect 6
    async.series [
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
    test.expect 3
    async.series [
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

exports.testParallel =

  # Test that everything gets called.
  testBasic: (test) ->
    test.expect 1
    result = {}
    async.parallel [
      (cb) ->
        result[1] = true
        cb()
      (cb) ->
        result[2] = true
        cb()
      (cb) ->
        result[3] = true
        cb()
    ], (err) ->
      test.equal err, null, 'No error'
      test.done()

  # Test that the finall callback gets called with an empty list.
  testEmpty: (test) ->
    test.expect 1
    async.parallel [], (err) ->
      test.equal err, null, 'No error'
      test.done()

  # Test a single error calls the final callback.
  testSingleError: (test) ->
    test.expect 1
    async.parallel [
      (cb) ->
        cb 'Some error'
    ], (err) ->
      test.equal err, 'Some error'
      test.done()

  # Test that only one error triggers the final callback.
  testMultipleError: (test) ->
    test.expect 1
    async.parallel [
      (cb) ->
        cb 'Error 1'
      (cb) ->
        cb 'Error 2' # This error is lost.
    ], (err) ->
      test.equal err, 'Error 1'
      test.done()

exports.testWhile =

  testBasic: (test) ->
    test.expect 2
    x = 0
    condition = (cb) ->
      return x < 9
    iterator = (cb) ->
      x++
      cb()
    finalCallback = (err) ->
      test.equal err, null, 'No error'
      test.equal x, 9, 'The loop ran 10 times.'
      test.done()
    async.while condition, iterator, finalCallback

  testError: (test) ->
    test.expect 2
    x = 0
    condition = ->
      return x < 10
    iterator = (cb) ->
      x++
      if x > 3
        cb 'Some error'
      else
        cb()
    finalCallback = (err) ->
      test.equal err, 'Some error'
      test.equal x, 4, 'The loop ran 5 times.'
      test.done()
    async.while condition, iterator, finalCallback

  testFalseConditionFromStart: (test) ->
    test.expect 2
    x = 0
    condition = ->
      return false
    iterator = (cb) ->
      x++
      cb()
    finalCallback = (err) ->
      test.equal err, null, 'No error'
      test.equal x, 0, 'The loop never ran.'
      test.done()
    async.while condition, iterator, finalCallback

exports.testForEachSeries =

  # Test that a simple foreach works.
  testBasic: (test) ->
    test.expect 2
    array = [1,2,3]
    newArray = []
    iterator = (x, cb) ->
      newArray.push x * 2
      cb()
    finalCallback = (err) ->
      test.equal err, null, 'No error'
      test.deepEqual [2, 4, 6], newArray
      test.done()
    async.forEachSeries array, iterator, finalCallback

  # Same as above but asynchronous.
  testBasicAsync: (test) ->
    test.expect 2
    array = [1,2,3]
    newArray = []
    iterator = (x, cb) ->
      newArray.push x * 2
      defer -> cb()
    finalCallback = (err) ->
      test.equal err, null, 'No error'
      test.deepEqual [2, 4, 6], newArray
      test.done()
    async.forEachSeries array, iterator, finalCallback

  # Test that an error stops the foreach and propagates.
  testError: (test) ->
    test.expect 2
    array = [1,2,3]
    newArray = []
    iterator = (x, cb) ->
      if x == 2
        cb '2 is unsupported'
      else
        newArray.push x * 2
        cb()
    finalCallback = (err) ->
      test.equal err, '2 is unsupported'
      test.deepEqual [2], newArray
      test.done()
    async.forEachSeries array, iterator, finalCallback

  # Same as above but asynchronous.
  testErrorAsync: (test) ->
    test.expect 2
    array = [1,2,3]
    newArray = []
    iterator = (x, cb) ->
      if x == 2
        defer -> cb '2 is unsupported'
      else
        newArray.push x * 2
        defer -> cb()
    finalCallback = (err) ->
      test.equal err, '2 is unsupported'
      test.deepEqual [2], newArray
      test.done()
    async.forEachSeries array, iterator, finalCallback

  # Test that an empty array never runs the loop.
  testEmptyArray: (test) ->
    test.expect 2
    array = []
    newArray = []
    iterator = (x, cb) ->
      newArray.push x * 2
      cb()
    finalCallback = (err) ->
      test.equal err, null
      test.deepEqual [], newArray
      test.done()
    async.forEachSeries array, iterator, finalCallback

exports.testForEachParallel =

  # Test that some tests happen in parallel.
  testBasic: (test) ->
    test.expect 1
    inFlight = 0
    iterator = (x, cb) ->
      inFlight++
      check = ->
        if inFlight == 3
          defer cb
        else
          defer check
      defer check
    finalCallback = (err) ->
      test.equal err, null
      test.done()
    async.forEachParallel ['a', 'b', 'c'], iterator, finalCallback

  # Test that the forEachParallel handles an empty list and still calls the final callback.
  testEmpty: (test) ->
    test.expect 2
    result = []
    iterator = (x, cb) ->
      result.push x
      cb()
    finalCallback = (err) ->
      test.equal err, null
      test.deepEqual result, []
      test.done()
    async.forEachParallel [], iterator, finalCallback

  # Test that forEachParallel collects errors and returns them.
  testError: (test) ->
    iterator = (x, cb) ->
      if x in [2, 7]
        cb "error #{ x }"
      else
        cb()
    finalCallback = (err) ->
      err.sort()
      test.deepEqual err, ['error 2', 'error 7']
      test.done()
    async.forEachParallel [1..10], iterator, finalCallback

  # Test that only N tasks are run at once.
  testLimit: (test) ->
    LIMIT = 1
    test.expect 3
    maxInFlight = 0
    currentInFlight = 0
    result = []
    iterator = (x, cb) ->
      currentInFlight++
      maxInFlight = currentInFlight if currentInFlight > maxInFlight
      tries = 0
      check = ->
        tries++
        if tries > 42
          currentInFlight--
          result.push x
          defer cb
        else
          defer check
      defer check
    finalCallback = (err) ->
      result.sort()
      test.equal maxInFlight, LIMIT
      test.deepEqual result, [1..9]
      test.equal err, null
      test.done()
    async.forEachParallel [1..9], iterator, LIMIT, finalCallback

