const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '..', '..', '.env') });

const User = require('../models/User');
const Gift = require('../models/Gift');
const VIPLevel = require('../models/VIPLevel');
const Vehicle = require('../models/Vehicle');
const DailyTask = require('../models/DailyTask');
const { v4: uuidv4 } = require('uuid');

// ─── GIFTS ────────────────────────────────────────────────────────────────────
const giftsData = [
  // Basic Gifts (50-300 coins)
  { sku: 'gift_rose', name: 'وردة حمراء', nameEn: 'Red Rose', type: 'basic', category: 'classic', priceCoins: 50, priceDiamonds: 0, requiresAnimation: false, requiresFullScreen: false, isActive: true, order: 1, icon: '🌹', color: '#FF1744', tags: ['رومانسي', 'كلاسيك'] },
  { sku: 'gift_heart', name: 'قلب نابض', nameEn: 'Beating Heart', type: 'animated', category: 'premium', priceCoins: 120, priceDiamonds: 0, requiresAnimation: true, requiresFullScreen: false, isActive: true, order: 2, icon: '💓', color: '#FF007F', animationUrl: '/assets/animations/heart.json', tags: ['رومانسي', 'قلب'] },
  { sku: 'gift_kiss', name: 'قبلة', nameEn: 'Kiss', type: 'basic', category: 'classic', priceCoins: 80, priceDiamonds: 0, requiresAnimation: false, requiresFullScreen: false, isActive: true, order: 3, icon: '💋', color: '#FF69B4', tags: ['رومانسي'] },
  { sku: 'gift_cake', name: 'كيك', nameEn: 'Cake', type: 'fullscreen', category: 'classic', priceCoins: 200, priceDiamonds: 0, requiresAnimation: false, requiresFullScreen: true, isActive: true, order: 4, icon: '🎂', color: '#FF9FF5', tags: ['مناسبة', 'عيد'] },
  { sku: 'gift_crown', name: 'تاج', nameEn: 'Crown', type: 'basic', category: 'vip', priceCoins: 300, priceDiamonds: 0, requiresAnimation: false, requiresFullScreen: false, isActive: true, order: 5, icon: '👑', color: '#FFD700', tags: ['VIP', 'تاج'] },
  { sku: 'gift_ring', name: 'خاتم', nameEn: 'Ring', type: 'fullscreen', category: 'premium', priceCoins: 500, priceDiamonds: 0, requiresAnimation: true, requiresFullScreen: true, isActive: true, order: 6, icon: '💍', color: '#00F5FF', tags: ['رومانسي', 'خطوبة'] },
  { sku: 'gift_rocket', name: 'صاروخ', nameEn: 'Rocket', type: 'animated', category: 'trending', priceCoins: 800, priceDiamonds: 0, requiresAnimation: true, requiresFullScreen: false, isActive: true, order: 7, icon: '🚀', color: '#FF4500', tags: ['مثير', 'قوي'] },
  { sku: 'gift_luxury_car', name: 'سيارة فاخرة', nameEn: 'Luxury Car', type: 'fullscreen', category: 'premium', priceCoins: 1500, priceDiamonds: 0, requiresAnimation: true, requiresFullScreen: true, isActive: true, order: 8, icon: '🏎️', color: '#FFD700', tags: ['فخم', 'سيارة'] },
  { sku: 'gift_yacht', name: 'يخت', nameEn: 'Yacht', type: 'fullscreen', category: 'vip', priceCoins: 3000, priceDiamonds: 0, requiresAnimation: true, requiresFullScreen: true, isActive: true, order: 9, icon: '🛥️', color: '#00BFFF', tags: ['VIP', 'فخم'] },
  { sku: 'gift_castle', name: 'قلعة', nameEn: 'Castle', type: 'fullscreen', category: 'vip', priceCoins: 5000, priceDiamonds: 0, requiresAnimation: true, requiresFullScreen: true, isActive: true, order: 10, icon: '🏰', color: '#6C63FF', tags: ['VIP', 'قلعة'] },
  { sku: 'gift_legendary_crown', name: 'التاج الأسطوري', nameEn: 'Legendary Crown', type: 'fullscreen', category: 'vip', priceCoins: 10000, priceDiamonds: 100, requiresAnimation: true, requiresFullScreen: true, isActive: true, order: 11, icon: '👑', color: '#FFD700', animationUrl: '/assets/animations/legendary_crown.json', fullScreenDuration: 15000, tags: ['VIP', 'أسطوري', 'تاج'] },
  { sku: 'gift_galaxy', name: 'مجرة', nameEn: 'Galaxy', type: 'fullscreen', category: 'vip', priceCoins: 25000, priceDiamonds: 500, requiresAnimation: true, requiresFullScreen: true, isActive: true, order: 12, icon: '🌌', color: '#B400FF', animationUrl: '/assets/animations/galaxy.json', fullScreenDuration: 20000, tags: ['VIP', 'أسطوري', 'مجرة'] },
];

// ─── VEHICLES ─────────────────────────────────────────────────────────────────
const vehiclesData = [
  { sku: 'car_basic', name: 'سيارة عادية', nameEn: 'Basic Car', type: 'car', priceCoins: 500, durationDays: 30, isActive: true, meta: { color: '#6C63FF', model: 'sedan' } },
  { sku: 'car_sport', name: 'سيارة رياضية', nameEn: 'Sports Car', type: 'car', priceCoins: 1500, durationDays: 30, isActive: true, meta: { color: '#FF1744', model: 'sports' } },
  { sku: 'car_luxury', name: 'سيارة فاخرة', nameEn: 'Luxury Car', type: 'car', priceCoins: 3000, durationDays: 30, isActive: true, meta: { color: '#FFD700', model: 'luxury' } },
  { sku: 'plane_private', name: 'طائرة خاصة', nameEn: 'Private Jet', type: 'plane', priceCoins: 5000, durationDays: 30, isActive: true, meta: { color: '#FFFFFF', model: 'jet' } },
  { sku: 'yacht_premium', name: 'يخت فاخر', nameEn: 'Premium Yacht', type: 'yacht', priceCoins: 8000, durationDays: 30, isActive: true, meta: { color: '#00BFFF', model: 'superyacht' } },
  { sku: 'helicopter', name: 'هليكوبتر', nameEn: 'Helicopter', type: 'helicopter', priceCoins: 12000, durationDays: 30, isActive: true, meta: { color: '#FF4500', model: 'luxury' } },
  { sku: 'horse_white', name: 'حصان أبيض', nameEn: 'White Horse', type: 'horse', priceCoins: 20000, durationDays: 30, isActive: true, meta: { color: '#FFFFFF', model: 'stallion' } },
  { sku: 'legendary_throne', name: 'عرش أسطوري', nameEn: 'Legendary Throne', type: 'throne', priceCoins: 50000, durationDays: 60, isActive: true, meta: { color: '#FFD700', model: 'royal' } },
];

async function seedAll() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('📦 Connected to MongoDB');

    // ─── Seed Gifts ──────────────────────────────────────────────────────────
    console.log('\n🎁 Seeding gifts...');
    for (const gift of giftsData) {
      await Gift.findOneAndUpdate({ sku: gift.sku }, { $set: gift }, { upsert: true });
    }
    console.log(`   ✅ ${giftsData.length} gifts seeded`);

    // ─── Seed VIP Levels ─────────────────────────────────────────────────────
    console.log('\n👑 Seeding VIP levels...');
    const vipLevels = [
      { level: 1, name: 'VIP 1 - برونزي', badge: { key: 'vip1', label: 'VIP 1', color: '#CD7F32' }, frame: { key: 'vip1_frame', label: 'VIP 1 Frame', color: '#CD7F32' }, color: '#CD7F32', priceCoins: 100, requirements: { minChargeLevel: 100, minActivityLevel: 1, minDaysActive: 1 }, entryEffect: null, benefits: ['شارة VIP 1', 'إطار VIP 1', 'تأثير دخول بسيط', 'تحديد أولوية الدخول للغرف'] },
      { level: 2, name: 'VIP 2 - فضي', badge: { key: 'vip2', label: 'VIP 2', color: '#C0C0C0' }, frame: { key: 'vip2_frame', label: 'VIP 2 Frame', color: '#C0C0C0' }, color: '#C0C0C0', priceCoins: 500, requirements: { minChargeLevel: 500, minActivityLevel: 5, minDaysActive: 3 }, entryEffect: 'silver', benefits: ['شارة VIP 2', 'إطار VIP 2', 'تأثير دخول فضي', 'هدية ترحيب يومية', '50% خصم على الهدايا العادية'] },
      { level: 3, name: 'VIP 3 - ذهبي', badge: { key: 'vip3', label: 'VIP 3', color: '#FFD700' }, frame: { key: 'vip3_frame', label: 'VIP 3 Frame', color: '#FFD700' }, color: '#FFD700', priceCoins: 1500, requirements: { minChargeLevel: 1500, minActivityLevel: 10, minDaysActive: 7 }, entryEffect: 'gold', benefits: ['شارة VIP 3', 'إطار VIP 3', 'تأثير دخول ذهبي', 'هدية يومية بقيمة أعلى', 'دخول VIP للغرف الممتلئة'] },
      { level: 4, name: 'VIP 4 - بلاتيني', badge: { key: 'vip4', label: 'VIP 4', color: '#E5E4E2' }, frame: { key: 'vip4_frame', label: 'VIP 4 Frame', color: '#E5E4E2' }, color: '#E5E4E2', priceCoins: 3000, requirements: { minChargeLevel: 3000, minActivityLevel: 20, minDaysActive: 14 }, entryEffect: 'platinum', benefits: ['شارة VIP 4', 'إطار VIP 4', 'تأثير دخول بلاتيني', 'إنشاء غرف VIP', 'أولوية الدعم الفني'] },
      { level: 5, name: 'VIP 5 - الماسي', badge: { key: 'vip5', label: 'VIP 5', color: '#B9F2FF' }, frame: { key: 'vip5_frame', label: 'VIP 5 Frame', color: '#B9F2FF' }, color: '#B9F2FF', priceCoins: 6000, requirements: { minChargeLevel: 6000, minActivityLevel: 40, minDaysActive: 21 }, entryEffect: 'diamond', benefits: ['شارة VIP 5', 'إطار VIP 5', 'تأثير دخول ماسي', 'إهداء 3 هدايا مجانية يومياً', 'مقعد VIP محجوز'] },
      { level: 6, name: 'VIP 6 - الياقوتي', badge: { key: 'vip6', label: 'VIP 6', color: '#E0115F' }, frame: { key: 'vip6_frame', label: 'VIP 6 Frame', color: '#E0115F' }, color: '#E0115F', priceCoins: 12000, requirements: { minChargeLevel: 12000, minActivityLevel: 60, minDaysActive: 30 }, entryEffect: 'ruby', benefits: ['شارة VIP 6', 'إطار VIP 6', 'تأثير دخول ياقوتي', 'مضاعفة الهدايا المستقبلة', 'تحكم في الغرفة كمشرف'] },
      { level: 7, name: 'VIP 7 - الزمردي', badge: { key: 'vip7', label: 'VIP 7', color: '#50C878' }, frame: { key: 'vip7_frame', label: 'VIP 7 Frame', color: '#50C878' }, color: '#50C878', priceCoins: 25000, requirements: { minChargeLevel: 25000, minActivityLevel: 80, minDaysActive: 45 }, entryEffect: 'emerald', benefits: ['شارة VIP 7', 'إطار VIP 7', 'تأثير دخول زمردي', 'هدية أسبوعية خاصة', 'مقعد حصري في جميع الغرف'] },
      { level: 8, name: 'VIP 8 - الياقوت الأزرق', badge: { key: 'vip8', label: 'VIP 8', color: '#0F52BA' }, frame: { key: 'vip8_frame', label: 'VIP 8 Frame', color: '#0F52BA' }, color: '#0F52BA', priceCoins: 50000, requirements: { minChargeLevel: 50000, minActivityLevel: 100, minDaysActive: 60 }, entryEffect: 'sapphire', benefits: ['شارة VIP 8', 'إطار VIP 8', 'تأثير دخول ياقوت أزرق', 'سحب أرباح أسبوعي', 'إدارة وكالة'] },
      { level: 9, name: 'VIP 9 - التاج الملكي', badge: { key: 'vip9', label: 'VIP 9', color: '#FF2400' }, frame: { key: 'vip9_frame', label: 'VIP 9 Frame', color: '#FF2400' }, color: '#FF2400', priceCoins: 100000, requirements: { minChargeLevel: 100000, minActivityLevel: 150, minDaysActive: 90 }, entryEffect: 'royal', benefits: ['شارة VIP 9', 'إطار VIP 9', 'تأثير دخول تاج ملكي', 'هدية أسبوعية فاخرة', 'ظهور في قائمة الشرف'] },
      { level: 10, name: 'VIP 10 - الأسطوري', badge: { key: 'vip10', label: 'VIP 10', color: '#FFD700' }, frame: { key: 'vip10_frame', label: 'VIP 10 Frame', color: '#FFD700' }, color: '#FFD700', priceCoins: 500000, requirements: { minChargeLevel: 500000, minActivityLevel: 300, minDaysActive: 180 }, entryEffect: 'legendary', benefits: ['شارة VIP 10 الأسطورية', 'إطار VIP 10 الأسطوري', 'تأثير دخول أسطوري', 'جميع مزايا VIP مجاناً', 'هدية يومية أسطورية', 'مقعد ملكي حصري', 'ظهور خاص للملف الشخصي'] },
    ];
    for (const vip of vipLevels) {
      await VIPLevel.findOneAndUpdate({ level: vip.level }, { $set: { ...vip, isActive: true } }, { upsert: true });
    }
    console.log(`   ✅ ${vipLevels.length} VIP levels seeded`);

    // ─── Seed Vehicles ───────────────────────────────────────────────────────
    console.log('\n🚗 Seeding vehicles...');
    for (const vehicle of vehiclesData) {
      await Vehicle.findOneAndUpdate({ sku: vehicle.sku }, { $set: vehicle }, { upsert: true });
    }
    console.log(`   ✅ ${vehiclesData.length} vehicles seeded`);

    // ─── Seed Daily Tasks ────────────────────────────────────────────────────
    console.log('\n📋 Seeding daily tasks...');
    const tasksData = [
      { title: 'تسجيل الدخول اليومي', description: 'سجل دخولك اليومي واحصل على مكافأة', type: 'daily_login', reward: { coins: 50, diamonds: 5, xp: 10 }, requirement: { target: 1, unit: 'مرة' }, icon: 'login', isActive: true },
      { title: 'ساعة نشاط', description: 'اقضِ ساعة في التطبيق', type: 'activity_hours', reward: { coins: 100, diamonds: 10, xp: 20 }, requirement: { target: 60, unit: 'دقيقة' }, icon: 'timer', isActive: true },
      { title: 'إرسال هدية', description: 'أرسل هدية لأحد المستخدمين', type: 'send_gifts', reward: { coins: 80, diamonds: 8, xp: 15 }, requirement: { target: 3, unit: 'هدية' }, icon: 'gift', isActive: true },
      { title: 'دخول الغرف الصوتية', description: 'ادخل إلى 5 غرف صوتية', type: 'join_rooms', reward: { coins: 60, diamonds: 6, xp: 12 }, requirement: { target: 5, unit: 'غرفة' }, icon: 'mic', isActive: true },
      { title: 'دعوة الأصدقاء', description: 'ادعُ 3 أصدقاء للانضمام', type: 'invite_friends', reward: { coins: 200, diamonds: 20, xp: 40 }, requirement: { target: 3, unit: 'صديق' }, icon: 'people', isActive: true },
      { title: 'مشاركة محتوى', description: 'شارك منشوراً أو غرفة مع أصدقائك', type: 'share_content', reward: { coins: 40, diamonds: 4, xp: 8 }, requirement: { target: 2, unit: 'مشاركة' }, icon: 'share', isActive: true },
    ];
    for (const task of tasksData) {
      await DailyTask.findOneAndUpdate({ type: task.type }, { $set: task }, { upsert: true });
    }
    console.log(`   ✅ ${tasksData.length} daily tasks seeded`);

    console.log('\n🎉 All data seeded successfully!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Seed error:', err);
    process.exit(1);
  }
}

if (require.main === module) { seedAll(); }
