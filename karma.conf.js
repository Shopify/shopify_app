const karmaReporters = ['mocha-clean'];

function isDebug(argument) {
  return argument === '--debug';
}

module.exports = function(config) {
  config.set({
    mode: 'development',
    basePath: '',
    frameworks: ['mocha', 'chai-sinon'],
    files: [
      'app/assets/javascripts/**/*.js',
      'test/javascripts/**/*test.js',
    ],
    exclude: [
      // Exclude JS files that create 'DOMContentLoaded' event listeners
      'app/assets/javascripts/**/redirect.js',
    ],
    mochaReporter: {
      output: 'autowatch',
    },
    preprocessors: {
      'test/javascripts/**/*test.js': ['webpack'],
    },
    webpack: {
      mode: 'none',
      output: {
        hashFunction: 'rsa-sha512',
      },
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
