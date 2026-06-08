const Agency = require('../models/Agency');
const User = require('../models/User');
const Notification = require('../models/Notification');
const logger = require('../utils/logger');

async function createAgency(req, res) {
  try {
    const { name, description } = req.body;
    const ownerId = req.user.userId;
    
    if (!name) return res.status(400).json({ error: 'Name required' });
    
    const existing = await Agency.findOne({ name });
    if (existing) return res.status(400).json({ error: 'Agency name already exists' });
    
    const user = await User.findOne({ userId: ownerId });
    
    const agency = new Agency({
      name,
      description,
      ownerId,
      members: [{ userId: ownerId, role: 'owner', joinedAt: new Date() }],
      managers: [ownerId]
    });
    
    await agency.save();
    
    res.json({ ok: true, agency });
  } catch (err) {
    logger.error('createAgency error', err);
    res.status(500).json({ error: 'Failed to create agency' });
  }
}

async function getAgency(req, res) {
  try {
    const { agencyId } = req.params;
    const agency = await Agency.findOne({ agencyId }).lean();
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    res.json(agency);
  } catch (err) {
    logger.error('getAgency error', err);
    res.status(500).json({ error: 'Failed to get agency' });
  }
}

async function listAgencies(req, res) {
  try {
    const { page = 1, limit = 20 } = req.query;
    const agencies = await Agency.find({ isActive: true })
      .sort({ 'stats.rank': 1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .lean();
    
    const total = await Agency.countDocuments({ isActive: true });
    
    res.json({ agencies, total, page: parseInt(page), pages: Math.ceil(total / limit) });
  } catch (err) {
    logger.error('listAgencies error', err);
    res.status(500).json({ error: 'Failed to list agencies' });
  }
}

async function joinAgency(req, res) {
  try {
    const { agencyId } = req.params;
    const userId = req.user.userId;
    
    const agency = await Agency.findOne({ agencyId });
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    
    const isMember = agency.members.find(m => m.userId === userId);
    if (isMember) return res.status(400).json({ error: 'Already a member' });
    
    agency.members.push({ userId, role: 'member', joinedAt: new Date() });
    await agency.save();
    
    const user = await User.findOne({ userId });
    const owner = await User.findOne({ userId: agency.ownerId });
    
    if (owner) {
      const notif = new Notification({
        userId: agency.ownerId,
        type: 'agency',
        title: 'عضو جديد',
        body: `${user.displayName} انضم للوكالة`,
        data: { agencyId, userId }
      });
      await notif.save();
    }
    
    res.json({ ok: true, agency });
  } catch (err) {
    logger.error('joinAgency error', err);
    res.status(500).json({ error: 'Failed to join agency' });
  }
}

async function leaveAgency(req, res) {
  try {
    const { agencyId } = req.params;
    const userId = req.user.userId;
    
    const agency = await Agency.findOne({ agencyId });
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    
    if (agency.ownerId === userId) {
      return res.status(400).json({ error: 'Owner cannot leave. Transfer ownership first.' });
    }
    
    agency.members = agency.members.filter(m => m.userId !== userId);
    agency.managers = agency.managers.filter(id => id !== userId);
    await agency.save();
    
    res.json({ ok: true });
  } catch (err) {
    logger.error('leaveAgency error', err);
    res.status(500).json({ error: 'Failed to leave agency' });
  }
}

async function addManager(req, res) {
  try {
    const { agencyId } = req.params;
    const { userId } = req.body;
    const adminId = req.user.userId;
    
    const agency = await Agency.findOne({ agencyId });
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    if (agency.ownerId !== adminId) return res.status(403).json({ error: 'Only owner can manage' });
    
    if (!agency.managers.includes(userId)) {
      agency.managers.push(userId);
      const member = agency.members.find(m => m.userId === userId);
      if (member) member.role = 'manager';
    }
    
    await agency.save();
    res.json({ ok: true, agency });
  } catch (err) {
    logger.error('addManager error', err);
    res.status(500).json({ error: 'Failed to add manager' });
  }
}

async function getAgencyStats(req, res) {
  try {
    const { agencyId } = req.params;
    const agency = await Agency.findOne({ agencyId }).lean();
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    res.json({ stats: agency.stats, members: agency.members, reports: agency.reports });
  } catch (err) {
    logger.error('getAgencyStats error', err);
    res.status(500).json({ error: 'Failed to get stats' });
  }
}

async function createAgencyTask(req, res) {
  try {
    const { agencyId } = req.params;
    const { title, description, type, reward, target } = req.body;
    const adminId = req.user.userId;
    
    const agency = await Agency.findOne({ agencyId });
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    if (agency.ownerId !== adminId && !agency.managers.includes(adminId)) {
      return res.status(403).json({ error: 'Not authorized' });
    }
    
    agency.tasks.push({ title, description, type: type || 'daily', reward, target, status: 'active' });
    await agency.save();
    
    res.json({ ok: true, tasks: agency.tasks });
  } catch (err) {
    logger.error('createAgencyTask error', err);
    res.status(500).json({ error: 'Failed to create task' });
  }
}

async function getAgencyTasks(req, res) {
  try {
    const { agencyId } = req.params;
    const agency = await Agency.findOne({ agencyId }).select('tasks').lean();
    if (!agency) return res.status(404).json({ error: 'Agency not found' });
    res.json({ tasks: agency.tasks || [] });
  } catch (err) {
    logger.error('getAgencyTasks error', err);
    res.status(500).json({ error: 'Failed to get tasks' });
  }
}

module.exports = {
  createAgency, getAgency, listAgencies,
  joinAgency, leaveAgency, addManager,
  getAgencyStats, createAgencyTask, getAgencyTasks
};
