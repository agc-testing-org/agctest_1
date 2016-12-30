import Oauth2 from 'torii/providers/oauth2-code';
import {configurable} from 'torii/configuration';

var SalesforceOauth2 = Oauth2.extend({
    name:       'salesforce-oauth2',
    baseUrl: 'https://login.salesforce.com/services/oauth2/authorize',

    responseParams: ['code', 'state'],

    redirectUri: configurable('redirectUri', function(){
        // A hack that allows redirectUri to be configurable
        // but default to the superclass
        return this._super();
    })

});

export default SalesforceOauth2;
