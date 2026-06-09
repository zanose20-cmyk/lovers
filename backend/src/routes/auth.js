const express = require('express');
const router = express.Router();
const { googleLogin, createGuest, registerDevice, listDevices, revokeDevice } = require('../controllers/authController');
const { requireAuth } = require('../middleware/authMiddleware');

router.post('/google', googleLogin);
router.post('/guest', createGuest);
router.post('/devices/register', requireAuth, registerDevice);
router.get('/devices', requireAuth, listDevices);
router.post('/devices/revoke', requireAuth, revokeDevice);

module.exports = router;
