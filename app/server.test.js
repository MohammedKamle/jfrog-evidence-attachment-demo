const request = require('supertest');
const app = require('./server');

describe('Evidence Demo App', () => {
  describe('GET /hello', () => {
    it('should return 200 with hello message', async () => {
      const res = await request(app).get('/hello');
      expect(res.statusCode).toBe(200);
      expect(res.body.message).toBe('Hello, JFrog Evidence Demo!');
    });

    it('should return JSON content type', async () => {
      const res = await request(app).get('/hello');
      expect(res.headers['content-type']).toMatch(/json/);
    });
  });

  describe('GET /health', () => {
    it('should return 200 with healthy status', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('healthy');
    });

    it('should include a timestamp', async () => {
      const res = await request(app).get('/health');
      expect(res.body.timestamp).toBeDefined();
    });
  });

  describe('GET /', () => {
    it('should return app info', async () => {
      const res = await request(app).get('/');
      expect(res.statusCode).toBe(200);
      expect(res.body.name).toBe('evidence-demo-app');
      expect(res.body.endpoints).toContain('/hello');
      expect(res.body.endpoints).toContain('/health');
    });
  });
});
