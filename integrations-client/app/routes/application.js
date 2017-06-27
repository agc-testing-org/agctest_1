import Ember from 'ember';
import ApplicationRouteMixin from 'ember-simple-auth/mixins/application-route-mixin';

export default Ember.Route.extend(ApplicationRouteMixin,{

    sessionAccount: Ember.inject.service('session-account'),

    beforeModel() {
        return this._loadCurrentUser();
    },

    sessionAuthenticated() {
        this._super(...arguments);
        this._loadCurrentUser().catch(() => this.get('session').invalidate());
    },

    _loadCurrentUser() {
        return this.get('sessionAccount').loadCurrentUser();
    },

    actions: {
        error(error, transition) {
            if(error && error.errors[0].status === "403"){
                this.transitionTo("/limit");
                return false;
            }
            else if(error && error.errors[0].status === "401"){
                //                            this.get('session').invalidate();
                this.transitionTo("/lost");
                return false;
            }
            if(error && error.errors[0].status === "404"){
                this.transitionTo("/lost");
                return false;
            }
        }
    }

});
