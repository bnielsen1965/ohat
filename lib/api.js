'use strict';

const ChildProcess = require('child_process');
const Net = require('net');

const Defaults = {
  path: '/api'
};

class Api {
  constructor (Config) {
    this.Config = Object.assign({}, Defaults, Config);
    if (!this.Config.authentication) {
      throw new Error('API requires an authentication module');
    }
    if (!this.Config.settingsStore) {
      throw new Error('API requires a settings storage module');
    }

    // methods that need to be bound to this instance
    this.changePassword = this._changePassword.bind(this);
    this.addUser = this._addUser.bind(this);
    this.getUserList = this._getUserList.bind(this);
    this.deleteUser = this._deleteUser.bind(this);
    this.getOTGSubnet = this._getOTGSubnet.bind(this);
    this.setOTGSubnet = this._setOTGSubnet.bind(this);
    this.getSetting = this._getSetting.bind(this);
    this.setSetting = this._setSetting.bind(this);
  }

  openRoutes (app) {
    app.get(this.Config.path + '/ping', (req, res, next) => {
      res.json({ pong: new Date().toISOString() });
    });

    app.post(this.Config.path + '/auth', this.Config.authentication.processLogin);
  }

  secureRoutes (app) {
    app.get(this.Config.path + '/getsession', this.getSession);
    app.post(this.Config.path + '/changepassword', this.changePassword);
    app.post(this.Config.path + '/adduser', this.addUser);
    app.get(this.Config.path + '/getuserlist', this.getUserList);
    app.post(this.Config.path + '/deleteuser', this.deleteUser);
// TODO change routes to CRUD style
    app.get(this.Config.path + '/getotgsubnet', this.getOTGSubnet);
    app.post(this.Config.path + '/setotgsubnet', this.setOTGSubnet);

    app.get(this.Config.path + '/setting/:setting', this.getSetting);
    app.post(this.Config.path + '/setting/:setting', this.setSetting);

    app.get(this.Config.path + '/logout', this.Config.authentication.processLogout);
  }

  getSession (req, res, next) {
    res.json(req.session);
  }

  userInGroup (req, group) {
    if (!req.session || !req.session.groups || !req.session.groups.includes(group)) {
      return false;
    }
    return true;
  }

  _changePassword (req, res, next) {
    let username = req.session.username;
    this.Config.authentication.authenticate(username, req.body.oldPassword)
      .then(record => {
        return this.Config.authentication.changePassword(username, req.body.newPassword);
      })
      .then(() => {
        res.json({ success: true, message: 'Password changed' });
      })
      .catch(error => {
        res.json({ success: false, error: error.message });
      });
  }

  _addUser (req, res, next) {
    if (!this.userInGroup(req, 'admin')) {
      return res.json({ success: false, error: 'Not authorized' });
    }
    this.Config.authentication.saveUser(req.body.username, req.body.password, req.body.groups)
      .then (success => {
        if (!success) {
          throw new Error('Failed to save new user');
        }
        res.json({ success: true, message: 'Saved user ' + req.body.username });
      })
      .catch(error => {
        res.json({ success: false, error: error.message });
      });
  }

  _getUserList (req, res, next) {
    if (!this.userInGroup(req, 'admin')) {
      return res.json({ success: false, error: 'Not authorized' });
    }
    this.Config.authentication.getUserList()
      .then (userList => {
        res.json({ success: true, userList: userList });
      })
      .catch(error => {
        res.json({ success: false, error: error.message });
      });
  }

  _deleteUser (req, res, next) {
    this.Config.authentication.deleteUser(req.body.username)
      .then(success => {
        res.json({ success: success });
      })
      .catch(error => {
        res.json({ success: false, error: error.message });
      });
  }

  _getOTGSubnet (req, res, next) {
    ChildProcess.exec('./scripts/rpi-otg-ethernet-host/scripts/get-otg-subnet.sh', (error, stdout, stderr) => {
      if (error) {
        return res.json({ success: false, error: 'Failed to read subnet' });
      }
      res.json({ success: true, subnet: stdout.toString().trim() });
    });
  }

  _setOTGSubnet (req, res, next) {
    if (!Net.isIPv4(req.body.subnet)) {
      return res.json({ success: false, error: 'Not a valid ipv4 address' });
    }
    if (! /\.0$/.test(req.body.subnet)) {
      return res.json({ success: false, error: 'Subnet must end with .0' });
    }
    if (/\.0\./.test(req.body.subnet)) {
      return res.json({ success: false, error: 'Subnet must be for a /24 netmask' });
    }

    ChildProcess.exec('sudo ./scripts/rpi-otg-ethernet-host/install.sh ' + req.body.subnet, (error, stdout, stderr) => {
      if (error) {
        return res.json({ success: false, error: 'Failed to set subnet' });
      }
      res.json({ success: true, message: 'Subnet accepted, reboot to use new settings' });
    });
  }

  _getSetting (req, res, next) {
    if (!req.params.setting) {
      throw new Error('Must specify setting in URL');
    }
    this.Config.settingsStore.getSetting(req.params.setting)
      .then(document => {
        res.json({ success: true, value: (document ? document.setting || undefined : undefined) });
      })
      .catch(error => {
        res.json({ success: false, error: error.message });
      });
  }

  _setSetting (req, res, next) {
    if (!req.params.setting) {
      throw new Error('Must specify setting in URL');
    }
    this.Config.settingsStore.setSetting(req.params.setting, req.body)
      .then(value => {
        res.json({ success: true, message: 'Setting saved (' + req.params.setting + ')' });
      })
      .catch(error => {
        res.json({ success: false, error: error.message });
      });
  }

}

module.exports = Api;
