var path = require('path');

var createPattern = function(path) {
  return {pattern: path, included: true, served: true, watched: false};
};

var framework = function(files) {
  files.unshift(createPattern(__dirname + '/adapter.js'));
  files.unshift(createPattern(path.dirname(require.resolve('sinon-chai')) + '/sinon-chai.js'));
  files.unshift(createPattern(path.dirname(require.resolve('chai')) + '/chai.js'));
  files.unshift(createPattern(path.dirname(require.resolve('sinon')) + '/../pkg/sinon.js'));
};

framework.$inject = ['config.files'];
module.exports = {'framework:chai-sinon': ['factory', framework]};