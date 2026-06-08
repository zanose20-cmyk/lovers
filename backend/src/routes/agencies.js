const express = require('express');
const router = express.Router();
const {
  createAgency, getAgency, listAgencies,
  joinAgency, leaveAgency, addManager,
  getAgencyStats, createAgencyTask, getAgencyTasks
} = require('../controllers/agenciesController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/', listAgencies);
router.get('/:agencyId', getAgency);
router.post('/', requireAuth, createAgency);
router.post('/:agencyId/join', requireAuth, joinAgency);
router.post('/:agencyId/leave', requireAuth, leaveAgency);
router.post('/:agencyId/managers', requireAuth, addManager);
router.get('/:agencyId/stats', getAgencyStats);
router.post('/:agencyId/tasks', requireAuth, createAgencyTask);
router.get('/:agencyId/tasks', getAgencyTasks);

module.exports = router;
