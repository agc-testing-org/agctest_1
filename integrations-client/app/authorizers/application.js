import Ember from 'ember';
import OAuth2Bearer from 'ember-simple-auth/authorizers/oauth2-bearer';

const { isEmpty } = Ember;

export default OAuth2Bearer.extend({
    authorize(data, block) {
        if (!isEmpty(data)) {
            console.log(data.access_token);
            console.log(data.github_token);
            block('Authorization', `Bearer ${data.access_token}`);
            if(!isEmpty(data.github_token)){
                block('Authorization-Github', `Bearer ${data.github_token}`);
            }
        }
    }
});
