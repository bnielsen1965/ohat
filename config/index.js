'use strict';

module.exports = {
  httpPort: 80,// 8080,
  httpsPort: 443,// 4443,
  keyFile: './certs/webserver.key',
  crtFile: './certs/webserver.crt',
  storageDirectory: 'store',
  authentication: {
    noAuthenticationPaths: ['/css', '/images', '/js'],
    homePage: 'index.html',
    loginPage: 'login.html',
    logoutPage: 'logout.html',
    groups: ['admin', 'user'],
    jwt: {
      secret: 'the site jwt secret'
    }
  }
};
