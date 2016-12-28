import Oauth2 from 'torii/providers/oauth2-code';
import {configurable} from 'torii/configuration';

var InstagramOauth2 = Oauth2.extend({
    name:       'instagram-oauth2',
    baseUrl: 'https://api.instagram.com/oauth/authorize',

    responseParams: ['code', 'state'],

    redirectUri: configurable('redirectUri', function(){
        // A hack that allows redirectUri to be configurable
        // but default to the superclass
        return this._super();
    })

});

export default InstagramOauth2;
