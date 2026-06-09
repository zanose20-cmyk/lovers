const express = require('express');
const router = express.Router();
const { submitReport, getMyReports } = require('../controllers/reportsController');
const { requireAuth } = require('../middleware/authMiddleware');

router.post('/', requireAuth, submitReport);
router.get('/my', requireAuth, getMyReports);

module.exports = router;
