const karmaReporters = ['mocha-clean'];

function isDebug(argument) {
  return argument === '--debug';
}

module.exports = function(config) {
  config.set({
    mode: 'development',
    basePath: '',
    frameworks: ['mocha-debug', 'mocha', 'chai-sinon'],
    files: [
      'app/assets/javascripts/**/*.js',
      'test/javascripts/**/*test.js',
    ],
    mochaReporter: {
      output: 'autowatch',
    },
    preprocessors: {
      'test/javascripts/**/*test.js': ['webpack'],
    },
    reporters: karmaReporters,
    port: 9876,
    colors: true,
    logLevel: config.LOG_WARN,
    autoWatch: false,
    browsers: ['ChromeHeadless'],
    singleRun: true,
    client: {
      mocha: {
        ui: 'tdd',
        grep: config.grep,
      },
    },
  });
};