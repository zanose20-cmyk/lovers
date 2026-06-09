const FriendRequest = require('../models/FriendRequest');
const User = require('../models/User');
const Notification = require('../models/Notification');
const admin = require('firebase-admin');
const logger = require('../utils/logger');

async function sendRequest(req, res) {
  try {
    const fromUserId = req.user.userId;
    const { toUserId } = req.body;
    if (!toUserId) return res.status(400).json({ error: 'toUserId required' });
    if (toUserId === fromUserId) return res.status(400).json({ error: 'Cannot add yourself' });

    const receiver = await User.findOne({ userId: toUserId });
    if (!receiver) return res.status(404).json({ error: 'User not found' });

    const existing = await FriendRequest.findOne({
      $or: [
        { fromUserId, toUserId, status: 'pending' },
        { fromUserId: toUserId, toUserId: fromUserId, status: 'pending' }
      ]
    });
    if (existing) return res.status(400).json({ error: 'Request already exists' });

    const sender = await User.findOne({ userId: fromUserId });
    const alreadyFriends = (sender.friends || []).includes(toUserId);
    if (alreadyFriends) return res.status(400).json({ error: 'Already friends' });

    const request = new FriendRequest({ fromUserId, toUserId });
    await request.save();

    const notif = new Notification({
      userId: toUserId,
      type: 'friend_request',
      title: 'طلب صداقة',
      body: `${sender.displayName} يطلب إضافتك كصديق`,
      data: { requestId: request.requestId, fromUserId, fromUserName: sender.displayName }
    });
    await notif.save();

    // Send FCM push notification
    try {
      if (admin.apps.length > 0) {
        const tokens = (receiver.devices || []).map(d => d.pushToken).filter(Boolean);
        if (tokens.length > 0) {
          await admin.messaging().sendEachForMulticast({
            notification: {
              title: 'طلب صداقة',
              body: `${sender.displayName} يطلب إضافتك كصديق`,
            },
            data: { type: 'friend_request', requestId: request.requestId, fromUserId, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
            tokens,
          });
        }
      }
    } catch (fcmErr) {
      logger.error('FCM friend request error', fcmErr);
    }

    res.json({ ok: true, requestId: request.requestId });
  } catch (err) {
    logger.error('sendFriendRequest error', err);
    res.status(500).json({ error: 'Failed to send request' });
  }
}

async function getRequests(req, res) {
  try {
    const userId = req.user.userId;
    const received = await FriendRequest.find({ toUserId: userId, status: 'pending' }).lean();
    const sent = await FriendRequest.find({ fromUserId: userId, status: 'pending' }).lean();

    const fromIds = received.map(r => r.fromUserId);
    const toIds = sent.map(r => r.toUserId);
    const allIds = [...new Set([...fromIds, ...toIds])];
    const users = await User.find({ userId: { $in: allIds } }).select('userId displayName avatarUrl').lean();
    const userMap = {};
    for (const u of users) userMap[u.userId] = u;

    const enrichedReceived = received.map(r => ({ ...r, user: userMap[r.fromUserId] }));
    const enrichedSent = sent.map(r => ({ ...r, user: userMap[r.toUserId] }));

    res.json({ received: enrichedReceived, sent: enrichedSent });
  } catch (err) {
    logger.error('getFriendRequests error', err);
    res.status(500).json({ error: 'Failed to get requests' });
  }
}

async function acceptRequest(req, res) {
  try {
    const userId = req.user.userId;
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ error: 'requestId required' });

    const request = await FriendRequest.findOne({ requestId, toUserId: userId, status: 'pending' });
    if (!request) return res.status(404).json({ error: 'Request not found' });

    request.status = 'accepted';
    request.respondedAt = new Date();
    await request.save();

    await User.updateOne({ userId }, { $inc: { friendsCount: 1 }, $addToSet: { friends: request.fromUserId } });
    await User.updateOne({ userId: request.fromUserId }, { $inc: { friendsCount: 1 }, $addToSet: { friends: userId } });

    res.json({ ok: true });
  } catch (err) {
    logger.error('acceptFriendRequest error', err);
    res.status(500).json({ error: 'Failed to accept request' });
  }
}

async function rejectRequest(req, res) {
  try {
    const userId = req.user.userId;
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ error: 'requestId required' });

    const request = await FriendRequest.findOne({ requestId, toUserId: userId, status: 'pending' });
    if (!request) return res.status(404).json({ error: 'Request not found' });

    request.status = 'rejected';
    request.respondedAt = new Date();
    await request.save();

    res.json({ ok: true });
  } catch (err) {
    logger.error('rejectFriendRequest error', err);
    res.status(500).json({ error: 'Failed to reject request' });
  }
}

async function cancelRequest(req, res) {
  try {
    const userId = req.user.userId;
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ error: 'requestId required' });

    const request = await FriendRequest.findOne({ requestId, fromUserId: userId, status: 'pending' });
    if (!request) return res.status(404).json({ error: 'Request not found' });

    request.status = 'cancelled';
    await request.save();

    res.json({ ok: true });
  } catch (err) {
    logger.error('cancelFriendRequest error', err);
    res.status(500).json({ error: 'Failed to cancel request' });
  }
}

async function removeFriend(req, res) {
  try {
    const userId = req.user.userId;
    const { userId: friendId } = req.params;
    if (!friendId) return res.status(400).json({ error: 'userId required' });

    await User.updateOne({ userId }, { $inc: { friendsCount: -1 }, $pull: { friends: friendId } });
    await User.updateOne({ userId: friendId }, { $inc: { friendsCount: -1 }, $pull: { friends: userId } });

    res.json({ ok: true });
  } catch (err) {
    logger.error('removeFriend error', err);
    res.status(500).json({ error: 'Failed to remove friend' });
  }
}

async function listFriends(req, res) {
  try {
    const { userId } = req.params;
    const user = await User.findOne({ userId }).select('friends friendsCount').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });

    const friends = await User.find({ userId: { $in: user.friends || [] } })
      .select('userId displayName avatarUrl level isVerified')
      .lean();

    res.json({ friends, total: friends.length });
  } catch (err) {
    logger.error('listFriends error', err);
    res.status(500).json({ error: 'Failed to list friends' });
  }
}

module.exports = { sendRequest, getRequests, acceptRequest, rejectRequest, cancelRequest, removeFriend, listFriends };
