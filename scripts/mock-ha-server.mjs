#!/usr/bin/env node
/**
 * Minimal Home Assistant API mock for local verification testing.
 */
import http from 'node:http';
import { WebSocketServer } from 'ws';

const port = Number(process.env.MOCK_HA_PORT || 8123);
const validToken = process.env.MOCK_HA_TOKEN || 'test-token';

const server = http.createServer((req, res) => {
  if (req.url === '/api/' && req.method === 'GET') {
    const auth = req.headers.authorization || '';
    if (auth !== `Bearer ${validToken}`) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Invalid access token or password' }));
      return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'API running.' }));
    return;
  }
  res.writeHead(404);
  res.end();
});

const wss = new WebSocketServer({ noServer: true });

server.on('upgrade', (req, socket, head) => {
  if (req.url !== '/api/websocket') {
    socket.destroy();
    return;
  }
  wss.handleUpgrade(req, socket, head, (ws) => {
    wss.emit('connection', ws, req);
  });
});

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'auth_required', ha_version: 'mock' }));
  ws.on('message', (data) => {
    let payload;
    try {
      payload = JSON.parse(data.toString());
    } catch {
      ws.send(JSON.stringify({ type: 'auth_invalid' }));
      return;
    }
    if (payload.type === 'auth' && payload.access_token === validToken) {
      ws.send(JSON.stringify({ type: 'auth_ok', ha_version: 'mock' }));
    } else {
      ws.send(JSON.stringify({ type: 'auth_invalid' }));
    }
  });
});

server.listen(port, '127.0.0.1', () => {
  console.error(`mock-ha listening on http://127.0.0.1:${port}`);
});
