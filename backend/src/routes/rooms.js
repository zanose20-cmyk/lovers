const express = require('express');
const router = express.Router();
const {
  createRoom, getRoom, listRooms, joinRoom, leaveRoom,
  muteUser, lockSeat, removeFromSeat, transferOwnership,
  setModerator, setCoOwner, updateRoomSettings, getRoomLogs, inviteToRoom,
  getVoiceAccess
} = require('../controllers/roomsController');
const { requireAuth } = require('../middleware/authMiddleware');

router.get('/', listRooms);
router.get('/:roomId', getRoom);
router.get('/:roomId/logs', requireAuth, getRoomLogs);
router.post('/', requireAuth, createRoom);
router.post('/:roomId/join', requireAuth, joinRoom);
router.post('/:roomId/leave', requireAuth, leaveRoom);
router.post('/:roomId/mute', requireAuth, muteUser);
router.post('/:roomId/lock-seat', requireAuth, lockSeat);
router.post('/:roomId/remove-seat', requireAuth, removeFromSeat);
router.post('/:roomId/transfer', requireAuth, transferOwnership);
router.post('/:roomId/moderator', requireAuth, setModerator);
router.post('/:roomId/co-owner', requireAuth, setCoOwner);
router.put('/:roomId/settings', requireAuth, updateRoomSettings);
router.post('/:roomId/invite', requireAuth, inviteToRoom);
router.post('/:roomId/voice-access', requireAuth, getVoiceAccess);

module.exports = router;
