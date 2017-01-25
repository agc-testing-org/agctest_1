import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
    this.route('token',{ path: '/token/:id' });
    this.route('forgot');
    this.route('login');
    this.route('home');
    this.route('project', {path: '/:org/project/:name'}, function() {
        this.route('index', {path: '/'});
    });
});

export default Router;
