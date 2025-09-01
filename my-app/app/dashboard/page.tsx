// app/dashboard/page.tsx
"use client";

import { useEffect, useState } from "react";
import { db } from "@/lib/firebaseClient";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  getDocs,
} from "firebase/firestore";

export default function DashboardPage() {
  const [logs, setLogs] = useState<any[]>([]);
  const [sessions, setSessions] = useState<any[]>([]);
  const [registeredUIDs, setRegisteredUIDs] = useState<Set<string>>(new Set());

  useEffect(() => {
    // --- Left panel: RFID Logs ---
    const logsQuery = query(
      collection(db, "rfidLogs"),
      orderBy("timestamp", "desc")
    );

    const unsubLogs = onSnapshot(logsQuery, (snapshot) => {
      setLogs(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    });

    // --- Right panel: Today's Sessions ---
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, "0");
    const dd = String(today.getDate()).padStart(2, "0");
    const todayId = `${yyyy}-${mm}-${dd}`;

    const sessionsQuery = collection(db, "rfidSessions", todayId, "cards");

    const unsubSessions = onSnapshot(sessionsQuery, (snapshot) => {
      setSessions(snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    });

    // --- Registered UIDs from users collection ---
    const fetchRegisteredUIDs = async () => {
      const usersSnap = await getDocs(collection(db, "users"));
      const allUIDs: string[] = [];

      for (const userDoc of usersSnap.docs) {
        const idsSnap = await getDocs(collection(userDoc.ref, "ids"));
        idsSnap.forEach((idDoc) => {
          const data = idDoc.data();
          if (data.id) allUIDs.push(data.id);
        });
      }

      setRegisteredUIDs(new Set(allUIDs));
    };

    fetchRegisteredUIDs();

    return () => {
      unsubLogs();
      unsubSessions();
    };
  }, []);

  return (
    <div className="flex gap-6 p-6">
      {/* Left: Logs */}
      <div className="flex-1 border rounded-lg p-4 shadow-md bg-white overflow-y-auto max-h-[80vh]">
        <h2 className="text-lg font-bold text-black mb-4">RFID Logs</h2>
        {logs.length === 0 ? (
          <p className="text-black">No logs yet.</p>
        ) : (
          <ul className="space-y-3 text-black">
            {logs.map((log) => {
              const isRegistered = registeredUIDs.has(log.uid);
              return (
                <li
                  key={log.id}
                  className={`p-3 border rounded text-sm ${
                    isRegistered
                      ? "border-black bg-gray-50"
                      : "border-red-500 bg-red-50"
                  }`}
                >
                  <p>
                    <span className="font-semibold text-black">UID:</span> {log.uid}
                  </p>
                  <p>
                    <span className="font-semibold text-black">MAC:</span>{" "}
                    {log.macAddress || "N/A"}
                  </p>
                  <p className="text-black text-xs">
                    {log.timestamp?.toDate
                      ? log.timestamp.toDate().toLocaleString()
                      : "—"}
                  </p>
                </li>
              );
            })}
          </ul>
        )}
      </div>

      {/* Right: Sessions */}
      <div className="flex-1 border rounded-lg p-4 shadow-md text-black bg-white overflow-y-auto max-h-[80vh]">
        <h2 className="text-lg font-bold mb-4">Today’s Sessions</h2>
        {sessions.length === 0 ? (
          <p className="text-gray-500">No sessions yet.</p>
        ) : (
          <ul className="space-y-3">
            {sessions.map((session) => (
              <li
                key={session.id}
                className="p-3 border rounded bg-gray-50 text-sm"
              >
                <p className="font-semibold">UID: {session.id}</p>
                <div className="mt-1 space-y-1 text-xs text-gray-700">
                  <p>
                    <strong>AM In:</strong>{" "}
                    {session.AMIn?.toDate
                      ? session.AMIn.toDate().toLocaleTimeString()
                      : "—"}
                  </p>
                  <p>
                    <strong>AM Out:</strong>{" "}
                    {session.AMOut?.toDate
                      ? session.AMOut.toDate().toLocaleTimeString()
                      : "—"}
                  </p>
                  <p>
                    <strong>PM In:</strong>{" "}
                    {session.PMIn?.toDate
                      ? session.PMIn.toDate().toLocaleTimeString()
                      : "—"}
                  </p>
                  <p>
                    <strong>PM Out:</strong>{" "}
                    {session.PMOut?.toDate
                      ? session.PMOut.toDate().toLocaleTimeString()
                      : "—"}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
