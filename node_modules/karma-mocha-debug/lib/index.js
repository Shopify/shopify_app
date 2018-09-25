var path = require('path');

var createPattern = function(path) {
    return {
        pattern: path,
        included: true,
        served: true,
        watched: false
    };
};

var initMochaDebug = function(files) {
    var mochaPath = path.dirname(require.resolve('mocha'));
    files.unshift(createPattern(__dirname + '/adapter.js'));
    files.unshift(createPattern(mochaPath + '/mocha.css'));
};

initMochaDebug.$inject = ['config.files'];

module.exports = {
    'framework:mocha-debug': ['factory', initMochaDebug]
};
