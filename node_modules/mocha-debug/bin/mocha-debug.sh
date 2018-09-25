#! /bin/sh
node --expose-internals ${BASH_SOURCE%/*}/../mocha-debug.js
