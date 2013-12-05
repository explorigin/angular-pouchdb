module.exports = function(config){
    config.set({
    basePath : '',

    files : [
      'external/angular-1.2.3.js',
      'external/angular-mocks.js',
      'external/pouchdb-nightly.js',
      'test/*.js',
      'angular-pouchdb.js'
    ],

    exclude : [
      'app/lib/angular/angular-loader.js',
      'app/lib/angular/*.min.js',
      'app/lib/angular/angular-scenario.js'
    ],

    autoWatch : true,

    frameworks: ['jasmine'],

    browsers : ['Chrome'],

    plugins : [
            'karma-junit-reporter',
            'karma-chrome-launcher',
            'karma-firefox-launcher',
            'karma-jasmine'
            ],

    junitReporter : {
      outputFile: 'test_out/unit.xml',
      suite: 'unit'
    }

})}
