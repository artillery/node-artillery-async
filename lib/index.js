// Generated by CoffeeScript 1.10.0
(function() {
  var slice = [].slice;

  exports.series = function(steps, finalCallback) {
    var index, processNextStep;
    index = 0;
    processNextStep = function(lastArgs) {
      var callback, finalArgs, nextArgs;
      if (lastArgs == null) {
        lastArgs = [];
      }
      if (steps[index] == null) {
        finalArgs = [null].concat(lastArgs);
        if (finalCallback != null) {
          finalCallback.apply(null, finalArgs);
        }
        return;
      }
      callback = function() {
        var args, err;
        err = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
        if (err != null) {
          if (typeof finalCallback === "function") {
            finalCallback(err);
          }
        } else {
          processNextStep(args);
        }
      };
      nextArgs = lastArgs.concat(callback);
      steps[index++].apply(null, nextArgs);
    };
    processNextStep();
  };

  exports.parallel = function(steps, finalCallback) {
    var barrier, count, errors, i, len, step;
    if (steps.length === 0) {
      if (typeof finalCallback === "function") {
        finalCallback(null);
      }
      return;
    }
    errors = [];
    count = steps.length;
    barrier = function(err) {
      if ((err != null) && count >= 0) {
        count = -1;
        if (typeof finalCallback === "function") {
          finalCallback(err);
        }
      } else {
        count--;
        if (count === 0) {
          if (typeof finalCallback === "function") {
            finalCallback(null);
          }
        }
      }
    };
    for (i = 0, len = steps.length; i < len; i++) {
      step = steps[i];
      step(barrier);
    }
  };

  exports["while"] = function(condition, iterator, finalCallback) {
    var process;
    process = function() {
      var callback;
      if (!condition()) {
        if (typeof finalCallback === "function") {
          finalCallback(null);
        }
        return;
      }
      callback = function(err) {
        if (err != null) {
          if (typeof finalCallback === "function") {
            finalCallback(err);
          }
        } else {
          process();
        }
      };
      iterator(callback);
    };
    process();
  };

}).call(this);