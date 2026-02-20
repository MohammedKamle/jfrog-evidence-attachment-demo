const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/hello', (req, res) => {
  res.json({ message: 'Hello, JFrog Evidence Demo!' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/', (req, res) => {
  res.json({
    name: 'evidence-demo-app',
    version: process.env.APP_VERSION || '1.0.0',
    endpoints: ['/hello', '/health'],
  });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Evidence Demo App running on port ${PORT}`);
  });
}

module.exports = app;
