const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const DailyTask = require('../models/DailyTask');

const defaultTasks = [
  {
    title: 'تسجيل الدخول اليومي',
    description: 'سجل دخولك اليومي واحصل على مكافأة',
    type: 'daily_login',
    reward: { coins: 50, diamonds: 5, xp: 10 },
    requirement: { target: 1, unit: 'مرة' },
    icon: 'login',
    isActive: true
  },
  {
    title: 'ساعة نشاط',
    description: 'اقضِ ساعة في التطبيق',
    type: 'activity_hours',
    reward: { coins: 100, diamonds: 10, xp: 20 },
    requirement: { target: 60, unit: 'دقيقة' },
    icon: 'timer',
    isActive: true
  },
  {
    title: 'إرسال هدية',
    description: 'أرسل هدية لأحد المستخدمين',
    type: 'send_gifts',
    reward: { coins: 80, diamonds: 8, xp: 15 },
    requirement: { target: 3, unit: 'هدية' },
    icon: 'gift',
    isActive: true
  },
  {
    title: 'دخول الغرف الصوتية',
    description: 'ادخل إلى 5 غرف صوتية',
    type: 'join_rooms',
    reward: { coins: 60, diamonds: 6, xp: 12 },
    requirement: { target: 5, unit: 'غرفة' },
    icon: 'mic',
    isActive: true
  },
  {
    title: 'دعوة الأصدقاء',
    description: 'ادعُ 3 أصدقاء للانضمام',
    type: 'invite_friends',
    reward: { coins: 200, diamonds: 20, xp: 40 },
    requirement: { target: 3, unit: 'صديق' },
    icon: 'people',
    isActive: true
  },
  {
    title: 'مشاركة محتوى',
    description: 'شارك منشوراً أو غرفة مع أصدقائك',
    type: 'share_content',
    reward: { coins: 40, diamonds: 4, xp: 8 },
    requirement: { target: 2, unit: 'مشاركة' },
    icon: 'share',
    isActive: true
  }
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');
    
    for (const task of defaultTasks) {
      await DailyTask.findOneAndUpdate(
        { type: task.type },
        { $set: task },
        { upsert: true }
      );
      console.log(`Task "${task.title}" seeded`);
    }
    
    console.log('Daily tasks seeding complete!');
    process.exit(0);
  } catch (err) {
    console.error('Seed error:', err);
    process.exit(1);
  }
}

if (require.main === module) { seed(); }
