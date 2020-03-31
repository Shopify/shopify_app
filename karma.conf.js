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
    exclude: [
      // Exclude JS files that create 'DOMContentLoaded' event listeners
      'app/assets/javascripts/**/redirect.js',
      'app/assets/javascripts/**/storage_access_redirect.js',
      'app/assets/javascripts/**/top_level_interaction.js',
      'app/assets/javascripts/**/partition_cookies.js',
    ],
    mochaReporter: {
      output: 'autowatch',
    },
    preprocessors: {
      'test/javascripts/**/*test.js': ['webpack'],
    },
    webpack: {},
    reporters: karmaReporters,
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
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
