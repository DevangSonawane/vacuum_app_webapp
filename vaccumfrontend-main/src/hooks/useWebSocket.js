// ============================================================
// src/hooks/useWebSocket.js
// WebSocket client hook — connects to /ws, authenticates,
// fires real-time notifications into the app.
// ============================================================

import { useEffect, useRef, useCallback, useState } from "react";

const WS_URL = "wss://vaccumapi-production.up.railway.app/ws";
// For local dev use: ws://localhost:3000/ws

export function useWebSocket({ onEvent } = {}) {
  const wsRef          = useRef(null);
  const pingRef        = useRef(null);
  const reconnectRef   = useRef(null);
  const mountedRef     = useRef(true);
  const [connected, setConnected] = useState(false);

  const connect = useCallback(() => {
    const token = localStorage.getItem("token");
    if (!token || !mountedRef.current) return;

    try {
      const ws = new WebSocket(WS_URL);
      wsRef.current = ws;

      ws.onopen = () => {
        if (!mountedRef.current) return ws.close();
        // Authenticate immediately on open
        ws.send(JSON.stringify({ type: "auth", token }));

        // Keep-alive ping every 25s
        pingRef.current = setInterval(() => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: "ping" }));
          }
        }, 25000);
      };

      ws.onmessage = (e) => {
        if (!mountedRef.current) return;
        try {
          const msg = JSON.parse(e.data);
          if (msg.event === "connected") {
            setConnected(true);
          }
          if (msg.event === "pong") return; // ignore pongs
          if (onEvent) onEvent(msg);
        } catch {}
      };

      ws.onclose = () => {
        setConnected(false);
        clearInterval(pingRef.current);
        // Reconnect after 4s if still mounted
        if (mountedRef.current) {
          reconnectRef.current = setTimeout(connect, 4000);
        }
      };

      ws.onerror = () => {
        ws.close();
      };
    } catch {}
  }, [onEvent]);

  useEffect(() => {
    mountedRef.current = true;
    connect();

    return () => {
      mountedRef.current = false;
      clearInterval(pingRef.current);
      clearTimeout(reconnectRef.current);
      if (wsRef.current) wsRef.current.close();
    };
  }, [connect]);

  return { connected };
}
