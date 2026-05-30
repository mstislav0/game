const WebSocket = require("ws");
const { randomBytes } = require("crypto");

const PORT = process.env.PORT || 8765;
const wss = new WebSocket.Server({ port: PORT });

const rooms = new Map();   // code → { players: Map<id, {ws, name}> }
const clients = new Map(); // ws → { id, roomCode }

function generateId() {
  return randomBytes(4).toString("hex");
}

function generateRoomCode() {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 4; i++) {
    if (i === 2) code += "-";
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

function send(ws, data) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

function broadcast(roomCode, data, excludeWs = null) {
  const room = rooms.get(roomCode);
  if (!room) return;
  for (const [, player] of room.players) {
    if (player.ws !== excludeWs) {
      send(player.ws, data);
    }
  }
}

wss.on("connection", (ws) => {
  const id = generateId();
  clients.set(ws, { id, roomCode: null });
  send(ws, { event: "connected", id });
  console.log(`[+] Client ${id} connected. Total: ${clients.size}`);

  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }

    const client = clients.get(ws);

    switch (msg.action) {
      case "create_room": {
        let code;
        do { code = generateRoomCode(); } while (rooms.has(code));

        const room = { players: new Map() };
        room.players.set(id, { ws, name: msg.name || "Космонавт" });
        rooms.set(code, room);
        client.roomCode = code;

        send(ws, { event: "room_created", code });
        console.log(`[R] Room ${code} created by ${id}`);
        break;
      }

      case "join_room": {
        const code = (msg.code || "").toUpperCase();
        const room = rooms.get(code);
        if (!room) {
          send(ws, { event: "error", message: `Комната ${code} не найдена` });
          return;
        }
        if (room.players.size >= 4) {
          send(ws, { event: "error", message: "Комната заполнена (макс. 4 игрока)" });
          return;
        }

        const playerName = msg.name || "Космонавт";
        room.players.set(id, { ws, name: playerName });
        client.roomCode = code;

        // Сообщаем вошедшему список игроков
        const playerList = [];
        for (const [pid, p] of room.players) {
          if (pid !== id) playerList.push({ id: pid, name: p.name });
        }
        send(ws, { event: "room_joined", code, players: playerList });

        // Остальным — новый игрок
        broadcast(code, { event: "player_joined", id, name: playerName }, ws);
        console.log(`[R] ${id} (${playerName}) joined room ${code}`);
        break;
      }

      case "move": {
        const code = client.roomCode;
        if (!code) return;
        broadcast(code, {
          event: "player_moved",
          id,
          x: msg.x ?? 0,
          y: msg.y ?? 0,
          z: msg.z ?? 0,
          ry: msg.ry ?? 0,
        }, ws);
        break;
      }
    }
  });

  ws.on("close", () => {
    const client = clients.get(ws);
    if (!client) return;
    const { roomCode } = client;

    if (roomCode) {
      const room = rooms.get(roomCode);
      if (room) {
        room.players.delete(id);
        broadcast(roomCode, { event: "player_left", id });
        if (room.players.size === 0) {
          rooms.delete(roomCode);
          console.log(`[R] Room ${roomCode} closed (empty)`);
        }
      }
    }

    clients.delete(ws);
    console.log(`[-] Client ${id} disconnected. Total: ${clients.size}`);
  });
});

console.log(`🚀 Space Hitchhikers relay server running on ws://0.0.0.0:${PORT}`);
