# artillery-async

[![Build Status](https://img.shields.io/circleci/project/artillery/node-artillery-async.svg)](https://circleci.com/gh/artillery/node-artillery-async)
[![Coverage Status](https://coveralls.io/repos/artillery/node-artillery-async/badge.svg?branch=master&service=github)](https://coveralls.io/github/artillery/node-artillery-async?branch=master)
[![License](https://img.shields.io/github/license/artillery/node-artillery-async.svg)](https://github.com/artillery/node-artillery-async/blob/master/LICENSE)
[![Issues](https://img.shields.io/github/issues/artillery/node-artillery-async.svg)](https://github.com/artillery/node-artillery-async/issues)

Common patterns for writing asynchronous code.

Install using `npm install artillery-async` or `bower install artillery-async`

## Why artillery-async instead of async?

- **async's API is difficult.** By comparison, artillery-async is only six functions. They're all we've needed after four years and tens of thousands of lines of JavaScript.
- **async is inconsistent.** async sometimes callbacks are executed synchronously. artillery-async does things synchronously when possible. Yes, this means you might overflow the call stack more easily, this provides the freedom to add `process.nextTick()` or `setImmediate()` only when you need it.
- **async's implementation is unweildly.** We had a lot of difficulty when debugging async -- there's a lot of code and a lot of misdirection. artillery-async is just over 100 lines of code.

## Contents

- [barrier](#asyncbarriercount-callback)
- [series](#asyncseriessteps-callback)
- [parallel](#asyncparallelsteps-callback)
- [while](#asyncwhilecondition-iterator-callback)
- [forEachSeries](#asyncforeachseriesitems-iterator-callback)
- [forEachParallel](#asyncforeachparallelitems-iterator-limit-callback)

## Functions

### async.barrier(count, callback)
- `count` Number
- `callback` Function(err)

Returns a function that executes `callback` after being called `count` times. The returned function takes no arguments. It's a like [parallel()][#parallel] but makes code simpler, especially when you don't need to keep track of errors.

#### Example

```javascript
var async = require('artillery-async');

function loadDependencies(deps, cb) {
  var i, barrier = async.barrier(deps.length, cb);
  for (i = 0; i < deps.length; i++) {
    (function(dep) {
      loadSingleItem(dep, function(err, contents) {
        if (err) console.error(dep + " didn't load: " + err);
        barrier();
      });
    })(deps[i]);
  }
}
```

### async.series(steps, callback)
- `steps` Array of Function([args...,] callback)
- `callback` Function(err[, args...])

Runs each function in `steps` serially, passing any callback arguments to the next function. (This is like async's `series()` and `waterfall()`.) When the last step has finished, `callback` is executed. If any step calls its callback with an error, the final `callback` is executed immediately with that error and no further steps are run.

This is the most popular function in this module. It's usually used as a control flow mechanism and to the cascading arguments aren't used that often but the technique can come in handy.

### Example

```javascript
var async = require('artillery-async');

async.series([
  function(cb) {
    fs.exists(path, cb);
  },
  function(exists, cb) {
    if (exists) fs.readFile(path, cb);
  },
  function(contents, cb) {
    request.post('https://example.com/upload', { form: { file: contents } }, cb);
  },
  function(res, body, cb) {
    cb(null, res.statusCode);
  }
], function(err, code) {
  if (err) {
    console.error('Error:', err);
  } else {
    console.log('Done! Got status code:', code);
  }
});
```

### async.parallel(steps, callback)
- `steps` Array of Function(callback)
- `callback` Function(err)

Runs each function in `steps` in parallel. When all steps have finished, `callback` is executed. Any errors produced by the steps are accumulated and passed to `callback` as an array.

#### Example

```javascript
var async = require('artillery-async');

app.get('/home', function(req, res) {
  var result = {};
  async.parallel([

    function getNews(cb) {
      db.news.getAll({ limit: 10 }, function(err, items) {
        result.news = items;
        cb(err);
      });
    },

    function getGames(cb) {
      db.games.getAll({ limit: 10 }, function(err, items) {
        result.games = items;
        cb(err);
      });
    },

  ], function(err) {
    if (err) {
      res.code(500).send(err);
    } else {
      res.render('home', result);
    }
  });

});
```

### async.while(condition, iterator, callback)
- `condition` Function()
- `iterator` Function(callback)
- `callback` Function(err)

Repeatedly calls `iterator` while the return value of `condition` is true or `iterator` calls its callback with and error, then `callback` is called, possibly with an error if `iterator` produced one.

#### Example

```javascript
var async = require('artillery-async');
var i = 0;

function cond() { return i <= 20; }

function iter(cb) {
  db.items.insert({ id: i++ }, cb);
}

async.while(cond, iter, function(err) {
  if (err) {
    console.error('Insert failed:', err);
  } else {
    console.log('Done!');
  }
});
```

### async.forEachSeries(items, iterator, callback)
- `items` Array
- `iterator` Function(item, callback)
- `callback` Function(err)

Calls `iterator` with each item in `items` in serial, finally calling `callback` at the end. If the `iterator` function calls its callback with an error, no more items are processed and `callback` is called with the error.

```javascript
var async = require('artillery-async');

async.forEachSeries(
  filesToRemove,
  function(filename, cb) {
    promptUser('Are you sure you want to delete ' + filename + '?', function(err, choice) {
      if (err) return cb(err);
      if (choice) {
        deleteRecursive(filename, cb);
      } else {
        cb();
      }
    });
  },
  function(err) {
    if (err) {
      showAlert('Error: ' + err);
    }
  }
);
```

### async.forEachParallel(items, iterator, [limit,] callback)
- `items` Array
- `iterator` Function(item, callback)
- `limit` (optional) Number
- `callback` Function(err)

Calls `iterator` with each item in `items` in parallel and calls `callback` when complete. If `limit` is specified, no more than that many `iterator`s will be in flight at any time. Any errors produced by the steps are accumulated and passed to `callback` as an array.

#### Example

```javascript
var async = require('artillery-async');

async.forEachParallel(
  filesToUpload,

  MAX_UPLOAD_CONCURRENCY, // 10 or so

  function(filename, cb) {
    fs.readFile(filename, function(err, contents) {
      if (err) return cb(err);
      s3.putObject({ Key: filename, Body: contents }, cb);
    });
  },

  function(err, code) {
    if (err) {
      console.error('Error:', err);
    } else {
      console.log('Done!');
    }
  }
);
```

## Notes

No mechanisms are provided for controlling the context. If you need the `this` variable, you'll need to scope it yourself (`var that = this;`) or use [`Function.bind()`](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Function/bind).
