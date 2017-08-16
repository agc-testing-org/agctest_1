import Ember from 'ember';
import config from 'integrations-client/config/environment';

export default Ember.Route.extend({
    splash: config.splash,
    beforeModel() {
        window.location.href = this.get("splash") + '/terms';
    }
});
