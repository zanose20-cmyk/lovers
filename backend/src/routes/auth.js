const express = require('express');
const router = express.Router();
const { firebaseLogin, createGuest, registerDevice, listDevices, revokeDevice } = require('../controllers/authController');
const { requireAuth } = require('../middleware/authMiddleware');

router.post('/firebase', firebaseLogin);
router.post('/guest', createGuest);
router.post('/devices/register', requireAuth, registerDevice);
router.get('/devices', requireAuth, listDevices);
router.post('/devices/revoke', requireAuth, revokeDevice);

module.exports = router;
