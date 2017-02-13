import Ember from 'ember';

export default Ember.Component.extend({
    showComment: false,
    session: Ember.inject.service('session'),
    actions: {
        displayComment(shouldDisplay){
            this.set("showComment",shouldDisplay);
        },
        comment(sprint,resource){
            var t = this;
            var comment = this.get("comment");
            if(comment.length < 500){
                this.get('session').authorize('authorizer:application', (headerName, headerValue) => {                            
                    Ember.$.ajax({                                      
                        method: "POST",                                                                     
                        url: "/comments/"+sprint+"/"+resource,
                        data: JSON.stringify({comment:comment}),
                        headers: {                                                                          
                            'Content-Type': "application/json",                                                                                     
                            'Authorization': headerValue                                                        
                        }                                                                                   
                    }).then((data,text,jqXHR)=>{
                        var parsed = JSON.parse(data);
                        if(parsed.success){
                            this.send("displayComment",false);
                            this.sendAction("pullResourcesNested");
                        }
                    }, function(xhr, status, error) {
                        reject(error);
                    });
                });
            }
            else{
                //comment too long
            }
        },
    }
});
