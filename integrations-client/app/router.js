import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
    this.route('token',{ path: '/token/:id' });
    this.route('forgot');
});

export default Router;
