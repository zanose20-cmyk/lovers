const config = require('../config');

let RtcTokenBuilder = null;
let RtcRole = null;
try {
  const AgoraToken = require('agora-token');
  RtcTokenBuilder = AgoraToken.RtcTokenBuilder;
  RtcRole = AgoraToken.RtcRole;
} catch (e) {
  // not installed; throw where used
}

function _mapRole(role) {
  if (!RtcRole) return role;
  if (!role) return RtcRole.PUBLISHER;
  if (typeof role === 'string') {
    const r = role.toLowerCase();
    if (r === 'subscriber' || r === 'audience') return RtcRole.SUBSCRIBER || 2;
    return RtcRole.PUBLISHER || 1;
  }
  return role;
}

function generateRtcToken(channelName, accountOrUid = 0, role = 'publisher', expireSeconds = 3600) {
  if (!RtcTokenBuilder) throw new Error('agora-token not installed');
  const appID = config.agoraAppId;
  const appCertificate = config.agoraAppCertificate;
  const now = Math.floor(Date.now() / 1000);
  const privilegeExpire = now + expireSeconds;
  const rtcRole = _mapRole(role);

  if (typeof accountOrUid === 'string' && accountOrUid !== '') {
    return RtcTokenBuilder.buildTokenWithAccount(appID, appCertificate, channelName, accountOrUid, rtcRole, privilegeExpire);
  }

  const uid = typeof accountOrUid === 'number' ? accountOrUid : 0;
  return RtcTokenBuilder.buildTokenWithUid(appID, appCertificate, channelName, uid, rtcRole, privilegeExpire);
}

module.exports = { generateRtcToken };
