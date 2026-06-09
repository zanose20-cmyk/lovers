const express = require('express');
const router = express.Router();
const {
  listVehicles, buyVehicle, equipVehicle,
  createVehicle, updateVehicle, deleteVehicle
} = require('../controllers/vehiclesController');
const { requireAuth } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/store/vehicles', listVehicles);
router.post('/store/vehicles/buy', requireAuth, buyVehicle);
router.post('/users/me/vehicles/equip', requireAuth, equipVehicle);
router.post('/admin/vehicles', requireAuth, requireRole('admin'), createVehicle);
router.put('/admin/vehicles/:sku', requireAuth, requireRole('admin'), updateVehicle);
router.delete('/admin/vehicles/:sku', requireAuth, requireRole('admin'), deleteVehicle);

module.exports = router;
