/*jshint node:true*/
/* global require, module */
var EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function(defaults) {
   
    var env = EmberApp.env()|| 'development';
    var isProductionLikeBuild = ['production', 'staging'].indexOf(env) > -1;

    var fingerprintOptions = {
        enabled: true,
        extensions: ['js', 'css', 'png', 'jpg', 'gif']
    };

    switch (env) {
        case 'staging':
            fingerprintOptions.prepend = 'TODO';
            break;
        case 'production':
            fingerprintOptions.prepend = 'https://s3-'+process.env.AWS_REGION+'.amazonaws.com/'+process.env.INTEGRATIONS_S3_BUCKET+'/';
            break;
    } 

    var app = new EmberApp(defaults, {

        fingerprint: fingerprintOptions || !isProductionLikeBuild,
        /*
        emberCLIDeploy: {
            runOnPostBuild: (env === 'development') ? 'development-postbuild' : false,
            shouldActivate: true
        },
        */
        sourcemaps: {
            enabled: !isProductionLikeBuild,
        },
        minifyCSS: { enabled: isProductionLikeBuild },
        minifyJS: { enabled: isProductionLikeBuild },

        tests: process.env.EMBER_CLI_TEST_COMMAND || !isProductionLikeBuild,
        hinting: process.env.EMBER_CLI_TEST_COMMAND || !isProductionLikeBuild

    });

    // Use `app.import` to add additional libraries to the generated
    // output files.
    //
    // If you need to use different assets in different
    // environments, specify an object as the first parameter. That
    // object's keys should be the environment name and the values
    // should be the asset to use in that environment.
    //
    // If the library that you are including contains AMD or ES6
    // modules that you would like to import into your application
    // please specify an object with the list of modules as keys
    // along with the exports of each module as its value.

    app.import('bower_components/tether/dist/js/tether.min.js');
    app.import('bower_components/bootstrap/dist/css/bootstrap.css');
    app.import('bower_components/bootstrap/dist/css/bootstrap.css.map', {
        destDir: 'assets'
    });
    app.import('bower_components/bootstrap/dist/js/bootstrap.js');
    app.import('bower_components/font-awesome/css/font-awesome.min.css');
    app.import('bower_components/font-awesome/fonts/FontAwesome.otf', {
        destDir: 'fonts'
    });
    app.import('bower_components/font-awesome/fonts/fontawesome-webfont.eot', {
        destDir: 'fonts'
    });
    app.import('bower_components/font-awesome/fonts/fontawesome-webfont.svg', {
        destDir: 'fonts'
    });
    app.import('bower_components/font-awesome/fonts/fontawesome-webfont.ttf', {
        destDir: 'fonts'
    });
    app.import('bower_components/font-awesome/fonts/fontawesome-webfont.woff', {
        destDir: 'fonts'
    });
    app.import('bower_components/font-awesome/fonts/fontawesome-webfont.woff2', {
        destDir: 'fonts'
    });
    return app.toTree();
};
