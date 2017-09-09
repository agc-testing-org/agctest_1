import Ember from 'ember';

export default Ember.Component.extend({
    store: Ember.inject.service(),
    session: Ember.inject.service('session'),
    sessionAccount: Ember.inject.service('session-account'),
    count: 2,
    showingAll: false,
    errorMessage: null,
    on_team: false,
    team: Ember.computed.filterBy('teams','id', 1),
    init() {
        this._super(...arguments);
        var teams = this.get("teams");
        var team_id = this.get("job.team_id");
        var onTeam = teams.findBy('id',String(team_id));
        if(onTeam){
            this.set("on_team",true);
        }
    },
    actions: {
        showAll(yesNo){
            var number = 2; 
            if(yesNo){
                number = this.get("sprints").toArray().length;
            }
            this.set("count",number);
            this.set("showingAll",yesNo);
        },
        select(team_id, job_id, sprint_id){
            var _this = this;
            var store = this.get('store');

            _this.set("errorMessage",null);

            var projectUpdate = store.findRecord('job',job_id).then(function(job) {
                job.set('sprint_id', sprint_id);
                job.save().then(function() {

                }, function(xhr, status, error) {
                    var response = xhr.errors[0].detail;
                    _this.set("errorMessage",response);
                });
            });
        }
    }
});
