const Gift = require('../models/Gift');
const User = require('../models/User');
const Room = require('../models/Room');
const WalletTransaction = require('../models/WalletTransaction');
const logger = require('../utils/logger');

async function listGifts(req, res) {
  try {
    const gifts = await Gift.find().sort({ createdAt: 1 }).lean();
    res.json({ gifts });
  } catch (err) {
    logger.error('listGifts error', err);
    res.status(500).json({ error: 'Failed to list gifts' });
  }
}

async function sendGift(req, res) {
  try {
    const fromUser = req.user;
    const { toUserId, giftSku, count = 1, roomId } = req.body;
    if (!toUserId || !giftSku) return res.status(400).json({ error: 'toUserId and giftSku required' });
    const giftCount = Math.min(Math.max(parseInt(count) || 1, 1), 100);

    const sender = await User.findOne({ userId: fromUser.userId });
    const receiver = await User.findOne({ userId: toUserId });
    if (!sender || !receiver) return res.status(404).json({ error: 'User not found' });

    const gift = await Gift.findOne({ sku: giftSku });
    if (!gift) return res.status(404).json({ error: 'Gift not found' });

    const totalCoins = (gift.priceCoins || 0) * giftCount;
    const totalDiamonds = (gift.priceDiamonds || 0) * giftCount;

    // Basic balance check: use chargeLevel as coins for demo
    if ((sender.chargeLevel || 0) < totalCoins) return res.status(400).json({ error: 'Insufficient coins' });

    // apply changes
    sender.chargeLevel = (sender.chargeLevel || 0) - totalCoins;
    sender.giftsSentCount = (sender.giftsSentCount || 0) + giftCount;
    receiver.giftsReceivedCount = (receiver.giftsReceivedCount || 0) + giftCount;

    await sender.save();
    await receiver.save();

    // record transactions
    const txOut = new WalletTransaction({ userId: sender.userId, type: 'gift_sent', amountCoins: totalCoins, relatedUserId: receiver.userId, giftSku, roomId });
    const txIn = new WalletTransaction({ userId: receiver.userId, type: 'gift_received', amountCoins: 0, relatedUserId: sender.userId, giftSku, roomId });
    await txOut.save();
    await txIn.save();

    // Emit socket event if roomId provided (non-blocking)
    try {
      const { emitToRoom } = require('../services/socket');
      if (roomId) emitToRoom(roomId, 'giftSent', { from: sender.userId, to: receiver.userId, gift: giftSku, count: giftCount, giftMeta: gift });
    } catch (e) {
      // ignore
    }

    res.json({ ok: true, txId: txOut.txId });
  } catch (err) {
    logger.error('sendGift error', err);
    res.status(500).json({ error: 'Failed to send gift', details: err.message });
  }
}

async function sendRoomGift(req, res) {
  try {
    const fromUser = req.user;
    const { roomId, giftSku, count = 1 } = req.body;
    if (!roomId || !giftSku) return res.status(400).json({ error: 'roomId and giftSku required' });

    const room = await Room.findOne({ roomId });
    if (!room) return res.status(404).json({ error: 'Room not found' });
    const receiver = await User.findOne({ userId: room.ownerId });
    if (!receiver) return res.status(404).json({ error: 'Room owner not found' });

    // reuse send logic but inlined for clarity
    const sender = await User.findOne({ userId: fromUser.userId });
    const gift = await Gift.findOne({ sku: giftSku });
    if (!sender || !gift) return res.status(404).json({ error: 'Sender or Gift not found' });

    const totalCoins = (gift.priceCoins || 0) * count;
    if ((sender.chargeLevel || 0) < totalCoins) return res.status(400).json({ error: 'Insufficient coins' });

    sender.chargeLevel = (sender.chargeLevel || 0) - totalCoins;
    sender.giftsSentCount = (sender.giftsSentCount || 0) + count;
    receiver.giftsReceivedCount = (receiver.giftsReceivedCount || 0) + count;
    await sender.save();
    await receiver.save();

    const txOut = new WalletTransaction({ userId: sender.userId, type: 'gift_sent', amountCoins: totalCoins, relatedUserId: receiver.userId, giftSku, roomId });
    const txIn = new WalletTransaction({ userId: receiver.userId, type: 'gift_received', amountCoins: 0, relatedUserId: sender.userId, giftSku, roomId });
    await txOut.save();
    await txIn.save();

    try {
      const { emitToRoom } = require('../services/socket');
      emitToRoom(roomId, 'roomGift', { from: sender.userId, to: receiver.userId, gift: giftSku, count, giftMeta: gift });
    } catch (e) {}

    res.json({ ok: true, txId: txOut.txId });
  } catch (err) {
    logger.error('sendRoomGift error', err);
    res.status(500).json({ error: 'Failed to send room gift', details: err.message });
  }
}

async function createGift(req, res) {
  try {
    const body = req.body || {};
    const gift = new Gift({
      sku: body.sku,
      name: body.name,
      type: body.type || 'normal',
      rarity: body.rarity || 'common',
      priceCoins: body.priceCoins || 0,
      priceDiamonds: body.priceDiamonds || 0,
      prices: body.prices || {},
      imageUrl: body.imageUrl,
      animationUrl: body.animationUrl,
      asset3dUrl: body.asset3dUrl,
      fullscreenEffect: !!body.fullscreenEffect,
      entryEffect: body.entryEffect,
      effects: body.effects || {},
      meta: body.meta || {}
    });
    await gift.save();
    res.json({ ok: true, gift });
  } catch (err) {
    logger.error('createGift error', err);
    res.status(500).json({ error: 'Failed to create gift', details: err.message });
  }
}

async function updateGift(req, res) {
  try {
    const sku = req.params.sku;
    const body = req.body || {};
    const allowedFields = ['name', 'type', 'rarity', 'priceCoins', 'priceDiamonds', 'prices', 'imageUrl', 'animationUrl', 'asset3dUrl', 'fullscreenEffect', 'entryEffect', 'effects', 'meta'];
    const updates = {};
    for (const field of allowedFields) {
      if (body[field] !== undefined) updates[field] = body[field];
    }
    const gift = await Gift.findOneAndUpdate({ sku }, { $set: updates }, { new: true });
    if (!gift) return res.status(404).json({ error: 'Gift not found' });
    res.json({ ok: true, gift });
  } catch (err) {
    logger.error('updateGift error', err);
    res.status(500).json({ error: 'Failed to update gift' });
  }
}

async function deleteGift(req, res) {
  try {
    const sku = req.params.sku;
    const gift = await Gift.findOneAndDelete({ sku });
    if (!gift) return res.status(404).json({ error: 'Gift not found' });
    res.json({ ok: true });
  } catch (err) {
    logger.error('deleteGift error', err);
    res.status(500).json({ error: 'Failed to delete gift', details: err.message });
  }
}

async function getGift(req, res) {
  try {
    const sku = req.params.sku;
    const gift = await Gift.findOne({ sku }).lean();
    if (!gift) return res.status(404).json({ error: 'Gift not found' });
    res.json(gift);
  } catch (err) {
    logger.error('getGift error', err);
    res.status(500).json({ error: 'Failed to get gift', details: err.message });
  }
}

module.exports = { listGifts, sendGift, sendRoomGift, createGift, updateGift, deleteGift, getGift };

