import { useEffect, useRef, useState } from "react";

const WS_BASE = "wss://apivdti.asynk.in";

export function useWebSocket({ onEvent } = {}) {
  const wsRef        = useRef(null);
  const pingRef      = useRef(null);
  const retryRef     = useRef(null);
  const mountedRef   = useRef(true);
  const onEventRef   = useRef(onEvent);
  const retryCount   = useRef(0);
  const [connected, setConnected] = useState(false);

  onEventRef.current = onEvent;

  useEffect(() => {
    mountedRef.current = true;

    function connect() {
      const token = localStorage.getItem("token");
      if (!token || !mountedRef.current) return;

      if (wsRef.current) {
        try { wsRef.current.close(); } catch {}
        wsRef.current = null;
      }

      try {
        const ws = new WebSocket(`${WS_BASE}?token=${token}`);
        wsRef.current = ws;

        ws.onopen = () => {
          if (!mountedRef.current) return ws.close();
          setConnected(true);
          retryCount.current = 0;

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
            if (msg.event === "pong") return;
            if (msg.event === "connected") { setConnected(true); return; }
            if (onEventRef.current) onEventRef.current(msg);
          } catch {}
        };

        ws.onclose = () => {
          setConnected(false);
          clearInterval(pingRef.current);
          wsRef.current = null;
          if (mountedRef.current) {
            const delay = Math.min(30000, 2000 * Math.pow(2, retryCount.current));
            retryCount.current++;
            retryRef.current = setTimeout(connect, delay);
          }
        };

        ws.onerror = () => {
          try { ws.close(); } catch {}
        };
      } catch {
        if (mountedRef.current) {
          const delay = Math.min(30000, 2000 * Math.pow(2, retryCount.current));
          retryCount.current++;
          retryRef.current = setTimeout(connect, delay);
        }
      }
    }

    connect();

    return () => {
      mountedRef.current = false;
      clearInterval(pingRef.current);
      clearTimeout(retryRef.current);
      if (wsRef.current) {
        try { wsRef.current.close(); } catch {}
      }
    };
  }, []);

  return { connected };
}
