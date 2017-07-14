import DS from 'ember-data';

const { attr, Model } = DS;

export default DS.Model.extend({
    created_at: attr('date'),
    updated_at: attr('date'),
    repo: attr('string'),
    commit: attr('string'),
    commit_remote: attr('string'),
    commit_success: attr('boolean'),
    sprint_state_id: attr('number'),
    comments: DS.hasMany('comment'),
    votes: DS.hasMany('vote'),
    preparing: attr('number'),
    prepared: attr('number'),
    poll: function() {
        if(this.get("preparing") != 0){
            var _this = this;
            Ember.run.later( function() {
                _this.reload(); 
                _this.poll();
            }, 5000);
        }
    }.observes('preparing'),
});
