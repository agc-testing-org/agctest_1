import LinkedInOauth2Provider from 'torii/providers/linked-in-oauth2';

export default LinkedInOauth2Provider.extend({
    fetch(data) {
        return data;
    }
});
