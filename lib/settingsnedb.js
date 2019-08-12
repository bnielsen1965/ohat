'use strict';

const NeDB = require('nedb');
const Path = require('path');

const Defaults = {
  storagePath: './',
  usersFile: 'settings.db'
};

class SettingsNeDB {
  constructor(Config) {
    this.Config = Object.assign({}, Defaults, Config);
    this.db = new NeDB({ filename: Path.join(this.Config.storagePath, this.Config.usersFile), autoload: true });
    this.db.ensureIndex({ fieldName: 'name', unique: true });
  }

  getSetting (name) {
    return new Promise((resolve, reject) => {
      this.db.find({ name: name }, (error, docs) => {
        resolve(docs && docs.length ? docs[0] : undefined);
      });
    });
  }

  setSetting (name, setting) {
    return new Promise((resolve, reject) => {
//      this.db.insert({ name: name, setting: setting }, (error, user) => {
      this.db.update({ name: name }, { name: name, setting: setting }, { upsert: true }, (error, doc) => {
        if (error) {
          reject(error);
          return;
        }
        resolve(doc);
      });
    });
  }

  removeSetting (name) {
    return new Promise((resolve, reject) => {
      this.db.remove({ name: name }, (error) => {
        if (error) {
          reject(error);
          return;
        }
        resolve(true);
      });
    })
  }

  changeSetting (name, setting) {
    return new Promise((resolve, reject) => {
      this.db.update({ name: name }, { $set: { setting: setting } }, (error) =>{
        if (error) {
          reject(error);
          return;
        }
        resolve(true);
      });
    })
  }
}

module.exports = SettingsNeDB;
