const request = require('supertest');
const mongoose = require('mongoose');
const { app } = require('../src/app');

let token;
let roomId;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/lovers';

beforeAll(async () => {
  await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 5000 });
  const res = await request(app)
    .post('/api/auth/guest')
    .send({});
  token = res.body.token;
}, 15000);

afterAll(async () => {
  await mongoose.disconnect();
});

describe('Health', () => {
  test('GET /health returns ok', async () => {
    const res = await request(app).get('/health').expect(200);
    expect(res.body.ok).toBe(true);
  }, 10000);
});

describe('Auth', () => {
  test('Guest login returns token and user', async () => {
    const res = await request(app)
      .post('/api/auth/guest')
      .send({})
      .expect(200);
    expect(res.body).toHaveProperty('token');
    expect(res.body).toHaveProperty('user');
    expect(res.body.user).toHaveProperty('userId');
  }, 10000);

  test('Firebase auth without body returns 400', async () => {
    const res = await request(app)
      .post('/api/auth/firebase')
      .send({})
      .expect(400);
    expect(res.body).toHaveProperty('error');
  }, 10000);

  test('Public rooms listing works without auth', async () => {
    await request(app).get('/api/rooms').expect(200);
  }, 10000);
});

describe('Rooms', () => {
  test('Create a room', async () => {
    const res = await request(app)
      .post('/api/rooms')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Jest Room', type: 'public', capacity: 12 })
      .expect(200);
    expect(res.body.room).toHaveProperty('roomId');
    expect(res.body.room.title).toBe('Jest Room');
    roomId = res.body.room.roomId;
  }, 10000);

  test('List rooms', async () => {
    const res = await request(app)
      .get('/api/rooms')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body).toHaveProperty('rooms');
    expect(Array.isArray(res.body.rooms)).toBe(true);
  }, 10000);

  test('Get room by ID', async () => {
    const res = await request(app)
      .get(`/api/rooms/${roomId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body).toHaveProperty('roomId', roomId);
  }, 10000);
});

describe('VIP', () => {
  test('Get VIP levels', async () => {
    const res = await request(app)
      .get('/api/vip/levels')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const levels = res.body.value || res.body.levels || res.body;
    expect(Array.isArray(levels) || typeof levels === 'object').toBe(true);
  }, 10000);
});

describe('Store', () => {
  test('Get gifts', async () => {
    const res = await request(app)
      .get('/api/store/gifts')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const gifts = res.body.value || res.body.gifts || res.body;
    expect(gifts).toBeDefined();
  }, 10000);

  test('Get vehicles', async () => {
    const res = await request(app)
      .get('/api/store/vehicles')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const vehicles = res.body.value || res.body.vehicles || res.body;
    expect(vehicles).toBeDefined();
  }, 10000);
});

describe('Tasks', () => {
  test('Get daily tasks', async () => {
    const res = await request(app)
      .get('/api/tasks/daily')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body).toHaveProperty('tasks');
    expect(res.body.tasks.length).toBe(6);
  }, 10000);

  test('Daily login', async () => {
    const res = await request(app)
      .post('/api/tasks/daily/login')
      .set('Authorization', `Bearer ${token}`)
      .send({})
      .expect(200);
    expect(res.body.ok).toBe(true);
  }, 10000);
});

describe('Wallet', () => {
  test('Get transactions', async () => {
    const res = await request(app)
      .get('/api/wallet/transactions')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.status).toBe(200);
  }, 10000);
});

describe('Users', () => {
  test('Search users', async () => {
    const res = await request(app)
      .get('/api/users/search?q=Guest')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body).toHaveProperty('users');
  }, 10000);
});

describe('404', () => {
  test('Non-existent route returns 404', async () => {
    const res = await request(app)
      .get('/api/non-existent')
      .expect(404);
    expect(res.body).toHaveProperty('code', 'ROUTE_NOT_FOUND');
  }, 10000);
});
