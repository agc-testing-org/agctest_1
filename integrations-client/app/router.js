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
    this.route('invitation', {path: '/invitation/:id'}, function(){
        this.route('resend');
    });
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
    this.route('profile',{ path: '/:id'}, function(){ // public profile
        this.route('requests');
    });
    this.route('me', function() { // private profile (logged in)
        this.route('notifications');
        this.route('connections');
        this.route('requests');
        this.route('invitation', {path: '/invitation/:id'});
    });
});

export default Router;
