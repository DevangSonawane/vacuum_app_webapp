// ============================================================
// src/context/NotificationContext.jsx
// Manages real-time notifications from WebSocket AND loads
// persisted history from GET /api/notifications on mount.
// ============================================================

import { createContext, useContext, useState, useCallback, useEffect } from "react";
import axios from "axios";
import { useWebSocket } from "../hooks/useWebSocket";

const NotificationContext = createContext();

const API_BASE_URL = "https://vaccumapi-production.up.railway.app/api";

const EVENT_LABELS = {
  job_raised:       { title: "New Job Raised",        color: "blue"    },
  job_status:       { title: "Job Status Updated",    color: "amber"   },
  report_submitted: { title: "Report Submitted",      color: "gray"    },
  report_reviewed:  { title: "Report Reviewed",       color: "emerald" },
  amc_expiring:     { title: "AMC Renewal Reminder",  color: "orange"  },
  amc_created:      { title: "New AMC Contract",      color: "blue"    },
  notification:     { title: "Notification",          color: "blue"    },
};

// Shape a DB row (from GET /api/notifications) into the same
// object the WS path produces, so the UI only needs one format.
const rowToItem = (row) => ({
  id:          row.id,
  event:       row.event,
  title:       row.title,
  color:       EVENT_LABELS[row.event]?.color || "blue",
  message:     row.message,
  entity_type: row.entity_type,
  entity_id:   row.entity_id,
  ts:          row.created_at,
  read:        row.is_read,
  fromDb:      true,
});

export function NotificationProvider({ children }) {
  const [notifications, setNotifications] = useState([]);
  const [unreadCount,   setUnreadCount]   = useState(0);

  // ── Load persisted notifications on mount ─────────────────
  useEffect(() => {
    const token = localStorage.getItem("token");
    if (!token) return;

    axios
      .get(`${API_BASE_URL}/notifications?limit=30`, {
        headers: { Authorization: `Bearer ${token}` },
      })
      .then((res) => {
        if (res.data.success) {
          const items = (res.data.data || []).map(rowToItem);
          setNotifications(items);
          setUnreadCount(res.data.unread_count || 0);
        }
      })
      .catch(() => {
        // Silently ignore — WS will still work for live events
      });
  }, []);

  // ── Add a new real-time notification (from WS) ─────────────
  const addNotification = useCallback((msg) => {
    const meta = EVENT_LABELS[msg.event] || EVENT_LABELS.notification;
    const item = {
      id:          Date.now() + Math.random(),
      event:       msg.event,
      title:       msg.data?.title  || meta.title,
      color:       meta.color,
      message:     msg.data?.message || formatEventMessage(msg),
      entity_type: msg.data?.entity_type || null,
      entity_id:   msg.data?.entity_id   || null,
      ts:          msg.ts || new Date().toISOString(),
      read:        false,
      fromDb:      false,
    };
    // Prepend and keep last 50
    setNotifications(p => [item, ...p].slice(0, 50));
    setUnreadCount(p => p + 1);
  }, []);

  // ── WebSocket event handler ───────────────────────────────
  const handleWsEvent = useCallback((msg) => {
    if (EVENT_LABELS[msg.event]) {
      addNotification(msg);
    }
  }, [addNotification]);

  const { connected } = useWebSocket({ onEvent: handleWsEvent });

  // ── Mark all as read — also calls the API ─────────────────
  const markAllRead = useCallback(async () => {
    setNotifications(p => p.map(n => ({ ...n, read: true })));
    setUnreadCount(0);
    try {
      const token = localStorage.getItem("token");
      if (token) {
        await axios.patch(
          `${API_BASE_URL}/notifications/read`,
          {},
          { headers: { Authorization: `Bearer ${token}` } }
        );
      }
    } catch {}
  }, []);

  // ── Mark one as read ──────────────────────────────────────
  const markRead = useCallback(async (id) => {
    setNotifications(p => p.map(n => n.id === id ? { ...n, read: true } : n));
    setUnreadCount(p => Math.max(0, p - 1));
    try {
      const token = localStorage.getItem("token");
      if (token) {
        await axios.patch(
          `${API_BASE_URL}/notifications/read`,
          { ids: [id] },
          { headers: { Authorization: `Bearer ${token}` } }
        );
      }
    } catch {}
  }, []);

  // ── Clear all — also calls the API ───────────────────────
  const clearAll = useCallback(async () => {
    setNotifications([]);
    setUnreadCount(0);
    try {
      const token = localStorage.getItem("token");
      if (token) {
        await axios.delete(
          `${API_BASE_URL}/notifications`,
          { headers: { Authorization: `Bearer ${token}` } }
        );
      }
    } catch {}
  }, []);

  return (
    <NotificationContext.Provider value={{
      notifications,
      unreadCount,
      connected,
      markAllRead,
      markRead,
      clearAll,
    }}>
      {children}
    </NotificationContext.Provider>
  );
}

export const useNotifications = () => useContext(NotificationContext);

// ── Format a human-readable message from WS event data ───────
function formatEventMessage(msg) {
  const d = msg.data || {};
  switch (msg.event) {
    case "job_raised":       return `${d.entity_id || "A new job"} was raised`;
    case "job_status":       return `${d.entity_id || "Job"} moved to "${d.status || "new status"}"`;
    case "report_submitted": return `${d.entity_id || "A report"} submitted for review`;
    case "report_reviewed":  return `${d.entity_id || "Report"} was ${d.status?.toLowerCase() || "reviewed"}`;
    case "amc_expiring":     return `${d.entity_id || "An AMC"} is expiring soon`;
    case "amc_created":      return `${d.entity_id || "A new AMC"} contract was created`;
    default:                 return d.message || "New notification";
  }
}