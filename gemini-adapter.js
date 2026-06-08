// ============================================================
// gemini-adapter.js
// Local HTTP adapter: OpenAI-compatible API → Google Gemini
// Berjalan di port 11434 (seperti Ollama)
// ============================================================

const http = require('http');
const https = require('https');

const PORT = 11434;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_BASE = 'generativelanguage.googleapis.com';

// Map model name: paperclip request → gemini model
const MODEL_MAP = {
  'gemini-2.0-flash':    'gemini-2.0-flash',
  'gemini-1.5-flash':    'gemini-1.5-flash',
  'gemini-1.5-pro':      'gemini-1.5-pro',
  'gpt-4o':              'gemini-2.0-flash',   // fallback
  'gpt-4':               'gemini-1.5-pro',      // fallback
  'gpt-3.5-turbo':       'gemini-1.5-flash',   // fallback
};

// ── Konversi format OpenAI messages → Gemini contents ────────
function convertMessages(messages) {
  const systemParts = [];
  const contents = [];

  for (const msg of messages) {
    if (msg.role === 'system') {
      systemParts.push({ text: msg.content });
    } else {
      const role = msg.role === 'assistant' ? 'model' : 'user';
      contents.push({
        role,
        parts: [{ text: msg.content || '' }]
      });
    }
  }

  return { systemParts, contents };
}

// ── Kirim request ke Gemini API ───────────────────────────────
function callGemini(model, messages, temperature, maxTokens) {
  return new Promise((resolve, reject) => {
    const geminiModel = MODEL_MAP[model] || 'gemini-2.0-flash';
    const { systemParts, contents } = convertMessages(messages);

    const body = {
      contents,
      generationConfig: {
        temperature: temperature ?? 0.7,
        maxOutputTokens: maxTokens ?? 2048,
      }
    };

    if (systemParts.length > 0) {
      body.systemInstruction = { parts: systemParts };
    }

    const bodyStr = JSON.stringify(body);
    const path = `/v1beta/models/${geminiModel}:generateContent?key=${GEMINI_API_KEY}`;

    const req = https.request({
      hostname: GEMINI_BASE,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(bodyStr),
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) return reject(new Error(parsed.error.message));

          // Ambil text dari Gemini response
          const text = parsed.candidates?.[0]?.content?.parts?.[0]?.text || '';

          // Format respons sesuai OpenAI ChatCompletion
          resolve({
            id: `chatcmpl-${Date.now()}`,
            object: 'chat.completion',
            created: Math.floor(Date.now() / 1000),
            model: geminiModel,
            choices: [{
              index: 0,
              message: { role: 'assistant', content: text },
              finish_reason: 'stop'
            }],
            usage: {
              prompt_tokens: 0,
              completion_tokens: 0,
              total_tokens: 0
            }
          });
        } catch (e) {
          reject(new Error('Failed to parse Gemini response: ' + data));
        }
      });
    });

    req.on('error', reject);
    req.write(bodyStr);
    req.end();
  });
}

// ── HTTP Server ───────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  const sendJSON = (code, data) => {
    res.writeHead(code, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  };

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    return res.end();
  }

  // Health check endpoint
  if (req.url === '/health' || req.url === '/') {
    return sendJSON(200, { status: 'ok', adapter: 'gemini', port: PORT });
  }

  // Models list (OpenAI compatible)
  if (req.url === '/v1/models') {
    return sendJSON(200, {
      object: 'list',
      data: Object.keys(MODEL_MAP).map(id => ({
        id, object: 'model', created: 1700000000, owned_by: 'google'
      }))
    });
  }

  // Chat completions endpoint
  if (req.url === '/v1/chat/completions' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body);
        const result = await callGemini(
          payload.model || 'gemini-2.0-flash',
          payload.messages || [],
          payload.temperature,
          payload.max_tokens
        );
        sendJSON(200, result);
      } catch (err) {
        console.error('[Gemini Adapter Error]', err.message);
        sendJSON(500, { error: { message: err.message, type: 'adapter_error' } });
      }
    });
    return;
  }

  // 404 untuk endpoint lain
  sendJSON(404, { error: 'Endpoint not found' });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`[Gemini Adapter] Berjalan di http://127.0.0.1:${PORT}`);
  console.log(`[Gemini Adapter] API Key: ${GEMINI_API_KEY ? '✓ Set' : '✗ MISSING!'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => { server.close(); process.exit(0); });
process.on('SIGINT',  () => { server.close(); process.exit(0); });
