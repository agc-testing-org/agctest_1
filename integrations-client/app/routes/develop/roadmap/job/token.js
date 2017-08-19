import Ember from 'ember';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin,{
    actions: {
        refresh(){
            this.refresh();
        }
    },
    model: function (params) {

        var share = this.get('store').createRecord('share-job', {
            token: params.token
        });
        share.save();

        return Ember.RSVP.hash({
            share: share
        });
    },
    afterModel(model,transition) {
        //        if(!model.share.get("valid")){
        this.transitionTo('develop.roadmap.job',this.paramsFor("develop.roadmap.job").id);
        //      }
    }
});
