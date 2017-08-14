/* jshint node: true */

module.exports = function(environment) {
  var ENV = {
    modulePrefix: 'integrations-client',
    environment: environment,
    rootURL: '/',
    locationType: 'auto',
    org: process.env.INTEGRATIONS_GITHUB_ORG,
    splash: process.env.INTEGRATIONS_SPLASH_HOST,
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. 'with-controller': true
      },
      EXTEND_PROTOTYPES: {
        // Prevent Ember Data from overriding Date.parse.
        Date: false
      }, 
    },

    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
    },
  };

  ENV.moment = {
      allowEmpty: true // default: false
  };

  ENV.torii = {
      sessionServiceName: 'session',
      providers: {
          'github-oauth2': {
              apiKey: process.env.INTEGRATIONS_GITHUB_CLIENT_ID,
              scope: "user:email public_repo",
              redirectUri: process.env.INTEGRATIONS_HOST+"/callback/github"
          },
          'linked-in-oauth2': {
              apiKey: process.env.INTEGRATIONS_LINKEDIN_CLIENT_ID,
              scope: "r_basicprofile",
              redirectUri: process.env.INTEGRATIONS_HOST+"/callback/linkedin" 
          }
      }
  };

  ENV['ember-simple-auth'] = {
      authorizer: 'simple-auth-authorizer:token',
      store: 'session-store:local-storage',
      authenticationRoute: 'login',
      routeIfAlreadyAuthenticated: 'me',
      routeAfterAuthentication: ''
  };

  ENV.contentSecurityPolicy = {
      'connect-src': "'self' http://localhost:4200"
  };

  if (environment === 'development') {
      // ENV.APP.LOG_RESOLVER = true;
      // ENV.APP.LOG_ACTIVE_GENERATION = true;
      // ENV.APP.LOG_TRANSITIONS = true;
      // ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
      // ENV.APP.LOG_VIEW_LOOKUPS = true;
  }

  if (environment === 'test') {
      // Testem prefers this...
      ENV.locationType = 'none';

      // keep test console output quieter
      ENV.APP.LOG_ACTIVE_GENERATION = false;
      ENV.APP.LOG_VIEW_LOOKUPS = false;

      ENV.APP.rootElement = '#ember-testing';
  }

  if (environment === 'production') {

  }

  return ENV;
};
