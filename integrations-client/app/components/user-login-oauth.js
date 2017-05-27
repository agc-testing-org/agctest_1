import Ember from 'ember';

const { getOwner } = Ember;

export default Ember.Component.extend({
    session: Ember.inject.service('session'),
    routes: Ember.inject.service('route-injection'),
    actions: {
        login(provider) {
            var t = this;

            var routeName = getOwner(this).lookup('controller:application').currentPath;
            var routeId = null;
         //   if(routeName === "sprint.index"){
           //     routeId = getOwner(this).lookup('router:main').router.state.params.sprint.id;
          //  }
            this.get('session').authenticate('authenticator:torii', provider).then(function(){

            }).catch((reason) => {
                console.log(reason);
            });

        }
    }
});
