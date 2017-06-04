export default Router;

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
    this.route('register');
    this.route('login'); 
    this.route('token',{ path: '/token/:id' });
    this.route('invitation', {path: '/invitation/:id'});
    this.route('registered-invitation', {path: '/registered-invitation/:id'});
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
    this.route('team', {path: '/team/:id'});
    this.route('profile',{ path: '/:username'}); // public profile
    this.route('me', function() { // private profile (logged in)
        this.route('notifications');
        this.route('connections');
        this.route('requests');
    });
    this.route('notifications');
    this.route('connections');
    this.route('requests');
    this.route('home2');
});

export default Router;
