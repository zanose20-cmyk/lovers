const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');
const logger = require('../utils/logger');

async function listVehicles(req, res) {
  try {
    const vehicles = await Vehicle.find({ isActive: true }).sort({ priceCoins: 1 }).lean();
    res.json(vehicles);
  } catch (err) {
    logger.error('listVehicles error', err);
    res.status(500).json({ error: 'Failed to list vehicles' });
  }
}

async function buyVehicle(req, res) {
  try {
    const userId = req.user.userId;
    const { sku, duration } = req.body;
    
    if (!sku) return res.status(400).json({ error: 'SKU required' });
    
    const vehicle = await Vehicle.findOne({ sku, isActive: true });
    if (!vehicle) return res.status(404).json({ error: 'Vehicle not found' });
    
    const user = await User.findOne({ userId });
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const days = duration || vehicle.durationDays || 30;
    const cost = vehicle.priceCoins * Math.ceil(days / (vehicle.durationDays || 30));
    
    if ((user.chargeLevel || 0) < cost) {
      return res.status(400).json({ error: 'Insufficient coins' });
    }
    
    user.chargeLevel = (user.chargeLevel || 0) - cost;
    
    // Add vehicle to user with expiry
    user.vehicles = user.vehicles || [];
    user.vehicles.push({
      sku: vehicle.sku,
      name: vehicle.name,
      type: vehicle.type,
      expiresAt: new Date(Date.now() + days * 24 * 60 * 60 * 1000),
      meta: vehicle.meta
    });
    
    await user.save();
    
    const tx = new WalletTransaction({
      userId,
      type: 'transfer',
      amountCoins: cost,
      status: 'ok'
    });
    await tx.save();
    
    res.json({ ok: true, vehicles: user.vehicles });
  } catch (err) {
    logger.error('buyVehicle error', err);
    res.status(500).json({ error: 'Failed to buy vehicle', details: err.message });
  }
}

async function createVehicle(req, res) {
  try {
    const vehicle = new Vehicle(req.body);
    await vehicle.save();
    res.json({ ok: true, vehicle });
  } catch (err) {
    logger.error('createVehicle error', err);
    res.status(500).json({ error: 'Failed to create vehicle' });
  }
}

async function updateVehicle(req, res) {
  try {
    const { sku } = req.params;
    const vehicle = await Vehicle.findOneAndUpdate({ sku }, { $set: req.body }, { new: true });
    if (!vehicle) return res.status(404).json({ error: 'Vehicle not found' });
    res.json({ ok: true, vehicle });
  } catch (err) {
    logger.error('updateVehicle error', err);
    res.status(500).json({ error: 'Failed to update vehicle' });
  }
}

async function deleteVehicle(req, res) {
  try {
    const { sku } = req.params;
    await Vehicle.findOneAndDelete({ sku });
    res.json({ ok: true });
  } catch (err) {
    logger.error('deleteVehicle error', err);
    res.status(500).json({ error: 'Failed to delete vehicle' });
  }
}

module.exports = {
  listVehicles, buyVehicle,
  createVehicle, updateVehicle, deleteVehicle
};
