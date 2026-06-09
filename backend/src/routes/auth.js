const express = require('express');
const router = express.Router();
const {
  googleLogin, facebookLogin, appleLogin,
  sendOTP, verifyOTP,
  createGuest,
  requestRecovery, verifyRecovery,
  registerDevice, listDevices, revokeDevice,
  deleteAccount,
  publicSeedVIP,
} = require('../controllers/authController');
const { requireAuth } = require('../middleware/authMiddleware');

router.post('/google', googleLogin);
router.post('/facebook', facebookLogin);
router.post('/apple', appleLogin);
router.post('/otp/send', sendOTP);
router.post('/otp/verify', verifyOTP);
router.post('/guest', createGuest);
router.post('/recovery/request', requestRecovery);
router.post('/recovery/verify', verifyRecovery);
router.post('/devices/register', requireAuth, registerDevice);
router.get('/devices', requireAuth, listDevices);
router.post('/devices/revoke', requireAuth, revokeDevice);

router.post('/delete-account', requireAuth, deleteAccount);

router.post('/seed-vip', publicSeedVIP);

module.exports = router;
