#!/usr/bin/env node
/**
 * Verifies Home Assistant WebSocket API reachability and token auth.
 * Exits 0 on success, 1 on failure. Prints a single-line status to stderr.
 */
const url = process.argv[2];
const token = process.argv[3];
const timeoutMs = Number(process.env.HA_TIMEOUT || 10) * 1000;

if (!url || !token) {
  console.error('usage: verify-ha-websocket.mjs <ws-url> <token>');
  process.exit(1);
}

const ws = new WebSocket(url);
let settled = false;

const fail = (message) => {
  if (settled) return;
  settled = true;
  console.error(`WebSocket: ${message}`);
  try {
    ws.close();
  } catch {
    /* ignore */
  }
  process.exit(1);
};

const succeed = (message) => {
  if (settled) return;
  settled = true;
  console.error(`WebSocket: ${message}`);
  ws.close();
  process.exit(0);
};

const timer = setTimeout(() => fail(`timeout after ${timeoutMs}ms`), timeoutMs);

ws.addEventListener('open', () => {
  /* wait for auth_required */
});

ws.addEventListener('message', (event) => {
  let payload;
  try {
    payload = JSON.parse(event.data);
  } catch {
    return fail('received non-JSON frame');
  }

  if (payload.type === 'auth_required') {
    ws.send(JSON.stringify({ type: 'auth', access_token: token }));
    return;
  }

  if (payload.type === 'auth_ok') {
    clearTimeout(timer);
    succeed('auth_ok');
    return;
  }

  if (payload.type === 'auth_invalid') {
    clearTimeout(timer);
    fail('auth_invalid — check HA_TOKEN');
  }
});

ws.addEventListener('error', () => {
  clearTimeout(timer);
  fail('connection error');
});

ws.addEventListener('close', () => {
  if (!settled) {
    clearTimeout(timer);
    fail('connection closed before auth_ok');
  }
});
