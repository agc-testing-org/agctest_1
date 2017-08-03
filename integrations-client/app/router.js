import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
    this.route('privacy');
    this.route('terms');
    this.route('forgot');
    this.route('register');
    this.route('login'); 
    this.route('token',{ path: '/token/:id' });
    this.route('invitation', {path: '/invitation/:id'}, function(){
        this.route('resend');
    });
    this.route('develop', function() {
        this.route('new');
        this.route('project', {path: '/:project_id'}, function() {
            this.route('state', {path: '/state/:id'});
            this.route('sprint', {path: '/sprint/:id'}, function() {
                this.route('state', { path: '/state/:state_id' });
            }); 
        });
    });
    this.route('roadmap');
    this.route('team', function(){
        this.route('new');
        this.route('select', {path: '/:id'}, function(){
            this.route('members');
            this.route('talent');
            this.route('owners');
            this.route('notifications');
            this.route('shares');
            this.route('leads');
            this.route('jobs');
        });
    });
    this.route('profile',{ path: '/wired/:id'}, function(){ // public profile
        this.route('requests');
        this.route('overview');
        this.route('comments');
        this.route('votes');
        this.route('contributions');
        this.route('comments-received');
        this.route('votes-received');
        this.route('contributions-selected');
        this.route('token', {path: '/:token'});
    });
    this.route('welcome');
    this.route('me', function() { // private profile (logged in)
        this.route('notifications');
        this.route('overview');
        this.route('connections');
        this.route('requests');
        this.route('invitation', {path: '/invitation/:id'});
        this.route('comments');
        this.route('votes');
        this.route('contributions');
        this.route('comments-received');
        this.route('votes-received');
        this.route('contributions-selected');
        this.route('settings', function(){
            this.route('notifications');
        });
    });

    this.route("limit");
    this.route("fourOhFour", { path: "*path"});
});

Router.reopen({
    sessionAccount: Ember.inject.service('session-account'),
    notifyGoogleAnalytics: Ember.on('didTransition', function() {
        if (!ga) { return; }
        ga('set', 'userId', this.get("sessionAccount.account.id"));
        return ga('send', 'pageview', {
            'page': this.get('url'),
            'title': this.get('url'),
        });
    })
});

export default Router;
