const router = require('express').Router();
const { requireAuth } = require('../middleware/authMiddleware');
const { sendRequest, getRequests, acceptRequest, rejectRequest, cancelRequest, removeFriend, listFriends } = require('../controllers/friendsController');

router.post('/send', requireAuth, sendRequest);
router.get('/requests', requireAuth, getRequests);
router.post('/accept', requireAuth, acceptRequest);
router.post('/reject', requireAuth, rejectRequest);
router.post('/cancel', requireAuth, cancelRequest);
router.delete('/:userId', requireAuth, removeFriend);
router.get('/:userId', listFriends);

module.exports = router;
