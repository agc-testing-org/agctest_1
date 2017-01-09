import Ember from 'ember';

const { inject: { service }, Component } = Ember;

export default Component.extend({
    session: service('session'),
    path: "/register",
    actions: {
        register() {
            var credentials = this.getProperties('token', 'password', 'path');
            this.get('session').authenticate('authenticator:custom', credentials).catch((reason) => {
                this.set('errorMessage', reason.error);
            });
        },
    }
});
