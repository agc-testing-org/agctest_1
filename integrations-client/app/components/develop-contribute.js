import Ember from 'ember';
import config from 'integrations-client/config/environment';

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    store: Ember.inject.service(),
    org: config.org,
    showingGit: false,
    actions: {
        showGit(){
            if(this.get("showingGit")){
                this.set("showingGit",false);
            }
            else{
                this.set("showingGit",true);
            }
        },
        submit(project_id, contributor_id){
            var _this = this;
            var store = this.get('store');

            var contributorUpdate = store.findRecord('contributor',contributor_id).then(function(contributor) {
                contributor.save().then(function() {
                    _this.sendAction("refresh");
                });
            });
        }
    }
});
