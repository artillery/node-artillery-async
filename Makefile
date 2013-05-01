#!/usr/bin/env coffee
#
# Copyright 2013 Artillery Games, Inc. All rights reserved.
#
# This code, and all derivative work, is the exclusive property of Artillery
# Games, Inc. and may not be used without Artillery Games, Inc.'s authorization#
#
# Author: Ian Langworth

async.js:
	coffee --compile --output lib src/async.coffee

test:
	nodeunit test

autobuild:
	coffee --watch --compile --output lib src/async.coffee

autotest:
	nodemon `which nodeunit` test
