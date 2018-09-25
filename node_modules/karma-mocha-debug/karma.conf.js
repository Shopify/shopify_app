module.exports = function(config) {
    config.set({
        basePath: '',
        frameworks: ['mocha-debug', 'mocha', 'expect'],
        files: [
            'test/*.js',
        ],
        plugins: [
            'karma-*',
            require('./lib/index.js')
        ],
        reporters: ['progress'],
        mocha: {
            reporter: 'html'
        },
        port: 9876,
        colors: true,
        logLevel: config.LOG_DEBUG,
        autoWatch: true,
        browsers: ['PhantomJS'],
        captureTimeout: 60000,
        singleRun: false
    });
};
