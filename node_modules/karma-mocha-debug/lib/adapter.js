(function(window, config) {
    var mocha = window.mocha;

    /**
     * Define reporter for mocha on debug.html page
     */
    if (/debug.html$/.test(window.location.pathname)) {
        var createMocharReporter = function(karmaConfig) {
            var mochaConfig = {};
            var reporter = 'html';

            if (karmaConfig && karmaConfig.mocha && karmaConfig.mocha.reporter) {
                reporter = karmaConfig.mocha.reporter;
            }

            mochaConfig.reporter = reporter;

            var mochaRunnerNode = document.createElement('div');
            mochaRunnerNode.setAttribute('id', 'mocha');
            document.body.appendChild(mochaRunnerNode);

            return mochaConfig;
        };

        mocha.setup(createMocharReporter(config));
    }

    /**
     * TODO(maksimrv): Move it to karma-mocha
     * Grep implementation for karma v0.11.*
     */
    if (config && config.args) {
        if (Object.prototype.toString.call(config.args) === '[object Array]') {
            config.args.join(' ').replace(/--grep=(\S+)?\s*/, function(match, grep) {
                mocha.grep(grep);
                return match;
            });
        }
    }

})(window, window.__karma__.config);
