import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
    this.route('index', {path: '/'});
    this.route('home');
    this.route('forgot');
    this.route('register', { path: '/register/:id'});
    this.route('token',{ path: '/token/:id' });
    this.route('forgot');
    this.route('develop', {path: '/develop'}, function() {
        this.route('index', {path: '/'});
        this.route('project', {path: '/:org/:name'}, function() {
            this.route('state', {path: '/state/:id'});
            this.route('sprint', {path: '/sprint/:id'}, function() {
                this.route('state', { path: '/state/:state_id' });
            }); 
        });
    });
    this.route('profile',{ path: '/:username'});
});

export default Router;
