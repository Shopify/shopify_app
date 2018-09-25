mocha-debug
===========

With Mocha 4 the maintainers made the decision to not terminate node, but instead let it hang if the code would naturally. That's awesome, but the recommended path of using `why-is-node-running` is super tedious given that you can't `mocha --expose-internals` so I built a wrapper to do that.

    npm install -g mocha-debug

In a situation where you run `mocha` and get back a script that doesn't terminate (even though the tests do). you can then run `mocha-debug` and it will expose whatever is still running at the end of the script.


Testing
-------
Nothing yet (oh, the irony).

Enjoy,

-Abbey Hawk Sparrow
