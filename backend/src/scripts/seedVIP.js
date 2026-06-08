const mongoose = require('mongoose');
const dotenv = require('dotenv');
dotenv.config();

const VIPLevel = require('../models/VIPLevel');

const vipData = [
  {
    level: 1,
    name: 'VIP 1 - برونزي',
    badge: { key: 'vip1', label: 'VIP 1', color: '#CD7F32' },
    frame: { key: 'vip1_frame', label: 'VIP 1 Frame', color: '#CD7F32' },
    color: '#CD7F32',
    benefits: ['شارة VIP 1', 'إطار VIP 1', 'تأثير دخول بسيط', 'تحديد أولوية الدخول للغرف'],
    requirements: { minChargeLevel: 100, minActivityLevel: 1, minDaysActive: 1 },
    priceCoins: 100
  },
  {
    level: 2,
    name: 'VIP 2 - فضي',
    badge: { key: 'vip2', label: 'VIP 2', color: '#C0C0C0' },
    frame: { key: 'vip2_frame', label: 'VIP 2 Frame', color: '#C0C0C0' },
    color: '#C0C0C0',
    benefits: ['شارة VIP 2', 'إطار VIP 2', 'تأثير دخول فضي', 'هدية ترحيب يومية', '50% خصم على الهدايا العادية'],
    requirements: { minChargeLevel: 500, minActivityLevel: 5, minDaysActive: 3 },
    priceCoins: 500
  },
  {
    level: 3,
    name: 'VIP 3 - ذهبي',
    badge: { key: 'vip3', label: 'VIP 3', color: '#FFD700' },
    frame: { key: 'vip3_frame', label: 'VIP 3 Frame', color: '#FFD700' },
    color: '#FFD700',
    benefits: ['شارة VIP 3', 'إطار VIP 3', 'تأثير دخول ذهبي', 'هدية يومية بقيمة أعلى', 'دخول VIP للغرف الممتلئة'],
    requirements: { minChargeLevel: 1500, minActivityLevel: 10, minDaysActive: 7 },
    priceCoins: 1500
  },
  {
    level: 4,
    name: 'VIP 4 - بلاتيني',
    badge: { key: 'vip4', label: 'VIP 4', color: '#E5E4E2' },
    frame: { key: 'vip4_frame', label: 'VIP 4 Frame', color: '#E5E4E2' },
    color: '#E5E4E2',
    benefits: ['شارة VIP 4', 'إطار VIP 4', 'تأثير دخول بلاتيني', 'إنشاء غرف VIP', 'أولوية الدعم الفني'],
    requirements: { minChargeLevel: 3000, minActivityLevel: 20, minDaysActive: 14 },
    priceCoins: 3000
  },
  {
    level: 5,
    name: 'VIP 5 - الماسي',
    badge: { key: 'vip5', label: 'VIP 5', color: '#B9F2FF' },
    frame: { key: 'vip5_frame', label: 'VIP 5 Frame', color: '#B9F2FF' },
    color: '#B9F2FF',
    benefits: ['شارة VIP 5', 'إطار VIP 5', 'تأثير دخول ماسي', 'إهداء 3 هدايا مجانية يومياً', 'مقعد VIP محجوز'],
    requirements: { minChargeLevel: 6000, minActivityLevel: 40, minDaysActive: 21 },
    priceCoins: 6000
  },
  {
    level: 6,
    name: 'VIP 6 - الياقوتي',
    badge: { key: 'vip6', label: 'VIP 6', color: '#E0115F' },
    frame: { key: 'vip6_frame', label: 'VIP 6 Frame', color: '#E0115F' },
    color: '#E0115F',
    benefits: ['شارة VIP 6', 'إطار VIP 6', 'تأثير دخول ياقوتي', 'مضاعفة الهدايا المستقبلة', 'تحكم في الغرفة كمشرف'],
    requirements: { minChargeLevel: 12000, minActivityLevel: 60, minDaysActive: 30 },
    priceCoins: 12000
  },
  {
    level: 7,
    name: 'VIP 7 - الزمردي',
    badge: { key: 'vip7', label: 'VIP 7', color: '#50C878' },
    frame: { key: 'vip7_frame', label: 'VIP 7 Frame', color: '#50C878' },
    color: '#50C878',
    benefits: ['شارة VIP 7', 'إطار VIP 7', 'تأثير دخول زمردي', 'هدية أسبوعية خاصة', 'مقعد حصري في جميع الغرف'],
    requirements: { minChargeLevel: 25000, minActivityLevel: 80, minDaysActive: 45 },
    priceCoins: 25000
  },
  {
    level: 8,
    name: 'VIP 8 - الياقوت الأزرق',
    badge: { key: 'vip8', label: 'VIP 8', color: '#0F52BA' },
    frame: { key: 'vip8_frame', label: 'VIP 8 Frame', color: '#0F52BA' },
    color: '#0F52BA',
    benefits: ['شارة VIP 8', 'إطار VIP 8', 'تأثير دخول ياقوت أزرق', 'سحب أرباح أسبوعي', 'إدارة وكالة'],
    requirements: { minChargeLevel: 50000, minActivityLevel: 100, minDaysActive: 60 },
    priceCoins: 50000
  },
  {
    level: 9,
    name: 'VIP 9 - التاج الملكي',
    badge: { key: 'vip9', label: 'VIP 9', color: '#FF2400' },
    frame: { key: 'vip9_frame', label: 'VIP 9 Frame', color: '#FF2400' },
    color: '#FF2400',
    benefits: ['شارة VIP 9', 'إطار VIP 9', 'تأثير دخول تاج ملكي', 'هدية أسبوعية فاخرة', 'ظهور في قائمة الشرف'],
    requirements: { minChargeLevel: 100000, minActivityLevel: 150, minDaysActive: 90 },
    priceCoins: 100000
  },
  {
    level: 10,
    name: 'VIP 10 - الأسطوري',
    badge: { key: 'vip10', label: 'VIP 10', color: '#FFD700' },
    frame: { key: 'vip10_frame', label: 'VIP 10 Frame', color: '#FFD700' },
    color: '#FFD700',
    entryEffect: 'legendary_entry',
    benefits: ['شارة VIP 10 الأسطورية', 'إطار VIP 10 الأسطوري', 'تأثير دخول أسطوري', 'جميع مزايا VIP مجاناً', 'هدية يومية أسطورية', 'مقعد ملكي حصري', 'ظهور خاص للملف الشخصي'],
    requirements: { minChargeLevel: 500000, minActivityLevel: 300, minDaysActive: 180 },
    priceCoins: 500000
  }
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');
    
    for (const data of vipData) {
      await VIPLevel.findOneAndUpdate(
        { level: data.level },
        { $set: data },
        { upsert: true }
      );
      console.log(`VIP Level ${data.level} seeded`);
    }
    
    console.log('VIP seeding complete!');
    process.exit(0);
  } catch (err) {
    console.error('Seed error:', err);
    process.exit(1);
  }
}

if (require.main === module) { seed(); }
