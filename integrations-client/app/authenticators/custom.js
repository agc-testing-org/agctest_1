import Ember from 'ember';
import Base from 'ember-simple-auth/authenticators/base';

const { RSVP, isEmpty, run, computed } = Ember;

export default Base.extend({

    _refreshTokenTimeout: null,
    refreshAccessTokens: true,
    serverTokenRevocationEndpoint: null,
    clientId: null,
    serverTokenEndpoint: "/session",

    restore(data) {
        var _this = this;
        return new RSVP.Promise((resolve, reject) => {
            const now                 = (new Date()).getTime();
            const refreshAccessTokens = _this.get('refreshAccessTokens');
            if (!isEmpty(data['expires_at']) && data['expires_at'] < now) {
                if (refreshAccessTokens) {
                    _this._refreshAccessToken(data['expires_in'], data['refresh_token']).then(resolve, reject);
                } else {
                    reject();
                }
            } else {
                if (isEmpty(data['access_token'])) {
                    reject();
                } else {
                    _this._scheduleAccessTokenRefresh(data['expires_in'], data['expires_at'], data['refresh_token']);
                    resolve(data);
                }
            }
        });
    },

    authenticate: function(options) {
        console.log("AUTHENTICATING WIRED7");
        var _this = this;
        return new Ember.RSVP.Promise((resolve, reject) => {
            Ember.$.ajax({
                url: options.path,
                type: 'POST',
                data: JSON.stringify({
                    email: options.email,
                    token: options.token,
                    password: options.password,
                    firstName: options.firstName
                }),
                contentType: 'application/json;charset=utf-8',
                dataType: 'json'
            }).then(function(response) {
                Ember.run(function() {
                    console.log("AUTHENTICATED WIRED7");

                    const expiresAt = _this._absolutizeExpirationTime(response['expires_in']);
                    _this._scheduleAccessTokenRefresh(response['expires_in'], expiresAt, response['refresh_token']);
                    if (!isEmpty(expiresAt)) {
                        response = Ember.merge(response, { 'expires_at': expiresAt });
                    }

                    resolve({
                        access_token: response.access_token
                    });
                });
            }, function(xhr, status, error) {
                var response = xhr.responseText;
                Ember.run(function() {
                    reject(response);
                });
            });
        });
    },

    _scheduleAccessTokenRefresh(expiresIn, expiresAt, refreshToken) {
        var _this = this;
        const refreshAccessTokens = _this.get('refreshAccessTokens');
        if (refreshAccessTokens) {
            const now = (new Date()).getTime();
            if (isEmpty(expiresAt) && !isEmpty(expiresIn)) {
                expiresAt = new Date(now + expiresIn * 1000).getTime();
            }
            const offset = (Math.floor(Math.random() * 5) + 5) * 1000;
            console.log("scheduling");
            console.log(expiresAt);
            console.log(offset);
            console.log(now);
            if (!isEmpty(refreshToken) && !isEmpty(expiresAt) && expiresAt > now - offset) {
                run.cancel(_this._refreshTokenTimeout);
                delete _this._refreshTokenTimeout;
                if (!Ember.testing) {
                    _this._refreshTokenTimeout = run.later(_this, _this._refreshAccessToken, expiresIn, refreshToken, expiresAt - now - offset);
                }
            }
        }
    },

    _refreshAccessToken(expiresIn, refreshToken) {
        var _this = this;
        const data                = { 'grant_type': 'refresh_token', 'refresh_token': refreshToken };
        const serverTokenEndpoint = this.get('serverTokenEndpoint'); 
            return new RSVP.Promise((resolve, reject) => {
                _this.makeRequest(serverTokenEndpoint, data).then((response) => {
                    run(() => {
                        expiresIn       = response['expires_in'] || expiresIn;
                        refreshToken    = response['refresh_token'] || refreshToken;
                        const expiresAt = _this._absolutizeExpirationTime(expiresIn);
                        const data      = Ember.merge(response, { 'expires_in': expiresIn, 'expires_at': expiresAt, 'refresh_token': refreshToken });
                        _this._scheduleAccessTokenRefresh(expiresIn, null, refreshToken);
                        console.log(data);
                        _this.trigger('sessionDataUpdated', data);
                        resolve(data);
                    });
                }, (xhr, status, error) => {
                    Ember.Logger.warn(`Access token could not be refreshed - server responded with ${error}.`);
                    reject();
                });
            });
    },

    invalidate: function() {
        console.log("SIGNED OUT");
        return Ember.RSVP.resolve();
    },

    _absolutizeExpirationTime(expiresIn) {
        if (!isEmpty(expiresIn)) {
            return new Date((new Date().getTime()) + expiresIn * 1000).getTime();
        }
    },

    _clientIdHeader: computed('clientId', function() {
        const clientId = this.get('clientId');

        if (!isEmpty(clientId)) {
            const base64ClientId = window.btoa(clientId.concat(':'));
            return { Authorization: `Basic ${base64ClientId}` };
        }
    }),

    makeRequest(url, data) {
        const options = {
            url,
            data,
            type:        'POST',
            dataType:    'json',
            contentType: 'application/x-www-form-urlencoded'
        };

        const clientIdHeader = this.get('_clientIdHeader');
        if (!isEmpty(clientIdHeader)) {
            options.headers = clientIdHeader;
        }

        return Ember.$.ajax(options);
    },
});
