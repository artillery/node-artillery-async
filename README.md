# artillery-async

Common patterns for writing asynchronous code.

This module is modeled after [async](https://npmjs.org/package/async) but with the following design goals:

1. Do things synchronously when possible.
1. A small, easy-to-remember API.
1. Simple and understandable implementation.

Note that the first goal may be construed as a limitation as passing thousands of synchronous callbacks to `series()` will overflow the call stack. This actually gives you more freedom -- you can add `setTimeout` or `process.nextTick` to your callbacks for fine-grained control over when you want functions to be called asynchronously.

No mechanisms are provided for controlling the context. If you need the `this` variable, you'll need to scope it yourself (`var that = this;`) or use [`Function.bind()`](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Function/bind).
