var log = require('why-is-node-running')
var Mocha = require('mocha'),
    fs = require('fs'),
    path = require('path');

// Instantiate a Mocha instance.
var mocha = new Mocha();

var current = process.cwd();
var testDir = current+'/test';

var dir = fs.readdirSync(testDir);

if(fs.existsSync('/test.js')){ //root test script
    mocha.addFile(
        path.join(current, 'test.js')
    );
}else{ // /test subdirectory
    dir.filter(function(file){
        // Only keep the .js files
        return file.substr(-3) === '.js';

    }).forEach(function(file){
        mocha.addFile(
            path.join(testDir, file)
        );
    });
}

// Run the tests.
mocha.run(function(failures){
    log();
    process.on('exit', function () {
        process.exit(failures);  // exit with non-zero status if there were failures
    });
});
