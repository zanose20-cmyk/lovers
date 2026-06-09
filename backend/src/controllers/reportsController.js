const Report = require('../models/Report');
const Notification = require('../models/Notification');
const User = require('../models/User');
const logger = require('../utils/logger');
const { v4: uuidv4 } = require('uuid');

async function submitReport(req, res) {
  try {
    const { targetType, targetId, reason, description } = req.body;
    const reporterId = req.user.userId;

    if (!targetType || !targetId || !reason) {
      return res.status(400).json({ error: 'targetType, targetId, and reason are required' });
    }

    if (targetType === 'user' && targetId === reporterId) {
      return res.status(400).json({ error: 'Cannot report yourself' });
    }

    const existing = await Report.findOne({ reporterId, targetType, targetId, status: 'pending' });
    if (existing) {
      return res.status(400).json({ error: 'You have already reported this' });
    }

    const report = new Report({
      reportId: uuidv4(),
      reporterId,
      targetType,
      targetId,
      reason,
      description: typeof description === 'string' ? description.slice(0, 1000) : '',
    });
    await report.save();

    res.json({ ok: true, reportId: report.reportId });
  } catch (err) {
    logger.error('submitReport error', err);
    res.status(500).json({ error: 'Failed to submit report' });
  }
}

async function getMyReports(req, res) {
  try {
    const reports = await Report.find({ reporterId: req.user.userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .lean();
    res.json({ reports });
  } catch (err) {
    logger.error('getMyReports error', err);
    res.status(500).json({ error: 'Failed to get reports' });
  }
}

module.exports = { submitReport, getMyReports };
