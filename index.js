/**
 * Created by lvbingru on 1/5/16.
 * Modified by flavordaave on 3/8/17
 */

import {NativeModules, NativeAppEventEmitter} from 'react-native';

const {WeiboAPI} = NativeModules;

const defaultScope = "all"
const defaultRedirectURI = "https://api.weibo.com/oauth2/default.html"

function checkData(data) {
    if(!data.redirectURI) {
        data.redirectURI = defaultRedirectURI
    }
    if(!data.scope) {
        data.scope = defaultScope
    }
}

function promiseBody(type, resolve, reject) {
  NativeAppEventEmitter.on('Weibo_Resp', result => {
    if (result.type === type) {
      if (result.errCode !== 0) {
          const err = new Error(result.errMsg);
          err.errCode = result.errCode;
          reject(err);
      } else {
          resolve(result);
      }
    }
  })
}

export function login(config={}) {
  checkData(config)
  return new Promise((resolve, reject) => {
    promiseBody('WBAuthorizeResponse', resolve, reject)
    WeiboAPI.login(config, ()=>{})
  })
}

export function share(data) {
  checkData(data)

  return new Promise((resolve, reject) => {
    promiseBody('WBSendMessageToWeiboResponse', resolve, reject)
    WeiboAPI.login(config, null)
  })
}
