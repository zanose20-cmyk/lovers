const DailyTask = require('../models/DailyTask');
const UserDailyProgress = require('../models/UserDailyProgress');
const User = require('../models/User');
const logger = require('../utils/logger');

function getDateString(date = new Date()) {
  return date.toISOString().split('T')[0];
}

async function getDailyTasks(req, res) {
  try {
    const userId = req.user.userId;
    const date = getDateString();
    
    const tasks = await DailyTask.find({ isActive: true }).lean();
    
    let progress = await UserDailyProgress.findOne({ userId, date });
    if (!progress) {
      progress = new UserDailyProgress({
        userId,
        date,
        tasks: tasks.map(t => ({
          taskId: t.taskId,
          progress: 0,
          target: t.requirement?.target || 1,
          completed: false,
          claimed: false
        }))
      });
      await progress.save();
    }
    
    // Combine task definitions with user progress
    const result = tasks.map(task => {
      const userTask = progress.tasks.find(t => t.taskId === task.taskId);
      return {
        ...task,
        progress: userTask?.progress || 0,
        target: userTask?.target || task.requirement?.target || 1,
        completed: userTask?.completed || false,
        claimed: userTask?.claimed || false
      };
    });
    
    res.json({
      tasks: result,
      dailyLogin: progress.dailyLogin,
      loginStreak: progress.loginStreak,
      activityMinutes: progress.activityMinutes,
      date
    });
  } catch (err) {
    logger.error('getDailyTasks error', err);
    res.status(500).json({ error: 'Failed to get daily tasks' });
  }
}

async function claimDailyReward(req, res) {
  try {
    const userId = req.user.userId;
    const date = getDateString();
    
    let progress = await UserDailyProgress.findOne({ userId, date });
    if (!progress) return res.status(404).json({ error: 'Progress not found. Get tasks first.' });
    
    const { taskId } = req.body;
    const taskDef = await DailyTask.findOne({ taskId, isActive: true });
    if (!taskDef) return res.status(404).json({ error: 'Task not found' });
    
    const taskProgress = progress.tasks.find(t => t.taskId === taskId);
    if (!taskProgress) return res.status(404).json({ error: 'Task progress not found' });
    
    if (!taskProgress.completed) return res.status(400).json({ error: 'Task not completed yet' });
    if (taskProgress.claimed) return res.status(400).json({ error: 'Task already claimed' });
    
    taskProgress.claimed = true;
    progress.coinsEarned += taskDef.reward.coins || 0;
    progress.xpEarned += taskDef.reward.xp || 0;
    
    // Update user
    const user = await User.findOne({ userId });
    if (user) {
      user.chargeLevel = (user.chargeLevel || 0) + (taskDef.reward.coins || 0);
      // XP would go toward leveling up
      await user.save();
    }
    
    await progress.save();
    
    res.json({
      ok: true,
      claimed: true,
      reward: taskDef.reward,
      totalCoinsEarned: progress.coinsEarned
    });
  } catch (err) {
    logger.error('claimDailyReward error', err);
    res.status(500).json({ error: 'Failed to claim reward' });
  }
}

async function dailyLogin(req, res) {
  try {
    const userId = req.user.userId;
    const date = getDateString();
    const yesterday = getDateString(new Date(Date.now() - 24 * 60 * 60 * 1000));
    
    let progress = await UserDailyProgress.findOne({ userId, date });
    if (!progress) {
      progress = new UserDailyProgress({ userId, date, tasks: [] });
    }
    
    if (progress.dailyLogin) {
      return res.json({ ok: true, alreadyLoggedIn: true, streak: progress.loginStreak });
    }
    
    progress.dailyLogin = true;
    
    // Check previous day login for streak
    const prevProgress = await UserDailyProgress.findOne({ userId, date: yesterday });
    if (prevProgress && prevProgress.dailyLogin) {
      progress.loginStreak = (prevProgress.loginStreak || 0) + 1;
    } else {
      progress.loginStreak = 1;
    }
    
    progress.lastLoginDate = date;
    await progress.save();
    
    // Update user last active
    await User.updateOne({ userId }, { $set: { lastActiveAt: new Date() } });
    
    res.json({
      ok: true,
      streak: progress.loginStreak,
      dailyLogin: true
    });
  } catch (err) {
    logger.error('dailyLogin error', err);
    res.status(500).json({ error: 'Failed to record daily login' });
  }
}

async function updateTaskProgress(req, res) {
  try {
    const userId = req.user.userId;
    const date = getDateString();
    const { taskId, increment = 1 } = req.body;
    
    let progress = await UserDailyProgress.findOne({ userId, date });
    if (!progress) return res.status(404).json({ error: 'Progress not found' });
    
    const taskProgress = progress.tasks.find(t => t.taskId === taskId);
    if (!taskProgress) return res.status(404).json({ error: 'Task not found' });
    
    taskProgress.progress += increment;
    if (taskProgress.progress >= taskProgress.target) {
      taskProgress.completed = true;
    }
    
    await progress.save();
    
    res.json({
      ok: true,
      taskId,
      progress: taskProgress.progress,
      target: taskProgress.target,
      completed: taskProgress.completed
    });
  } catch (err) {
    logger.error('updateTaskProgress error', err);
    res.status(500).json({ error: 'Failed to update progress' });
  }
}

async function createDailyTask(req, res) {
  try {
    const { title, description, type, reward, requirement, icon } = req.body;
    
    const task = new DailyTask({
      title,
      description,
      type,
      reward: reward || { coins: 0, diamonds: 0, xp: 0 },
      requirement: requirement || { target: 1 },
      icon
    });
    
    await task.save();
    res.json({ ok: true, task });
  } catch (err) {
    logger.error('createDailyTask error', err);
    res.status(500).json({ error: 'Failed to create task' });
  }
}

module.exports = {
  getDailyTasks, claimDailyReward, dailyLogin,
  updateTaskProgress, createDailyTask
};
