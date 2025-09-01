import { NextResponse } from "next/server";
import { db, fcm, admin } from "@/lib/firebaseAdmin";

// ✅ Helper: get PH-local date & time as Date object
function getPhilippinesDate(): Date {
  const now = new Date();
  // Convert to PH timezone (UTC+8) by adding 8 hours to UTC time
  const phTime = new Date(now.getTime() + (8 * 60 * 60 * 1000));
  return phTime;
}

export async function POST(req: Request) {
  try {
    const body = await req.json();

    // 🔹 PH-local date & time
    const nowPH = getPhilippinesDate();
    const yyyy = nowPH.getUTCFullYear(); // Use UTC methods since we adjusted the time
    const mm = String(nowPH.getUTCMonth() + 1).padStart(2, "0");
    const dd = String(nowPH.getUTCDate()).padStart(2, "0");

    // Save raw log
    await db.collection("rfidLogs").doc().set({
      ...body,
      // Store as proper Timestamp representing PH time
      timestamp: admin.firestore.Timestamp.fromDate(nowPH),
      localDate: `${yyyy}-${mm}-${dd}`,
      localTime: formatTimeForDisplay(nowPH), // Use helper function for display time
    });

    // 🔹 Find user linked to this card
    const usersSnap = await db.collection("users").get();
    let matchedUser: FirebaseFirestore.DocumentSnapshot | null = null;
    let matchedCard: FirebaseFirestore.DocumentSnapshot | null = null;

    for (const userDoc of usersSnap.docs) {
      const cardSnap = await userDoc.ref
        .collection("ids")
        .where("id", "==", body.uid)
        .get();
      if (!cardSnap.empty) {
        matchedUser = userDoc;
        matchedCard = cardSnap.docs[0];
        break;
      }
    }

    if (!matchedUser || !matchedCard) {
      console.log(`⚠️ Card ${body.uid} not linked to any user`);
      return NextResponse.json(
        { success: false, message: "Card not registered" },
        { status: 404 }
      );
    }

    // 🔹 Prepare session document
    const todayId = `${yyyy}-${mm}-${dd}`;
    const sessionRef = db
      .collection("rfidSessions")
      .doc(todayId)
      .collection("cards")
      .doc(body.uid);

    const sessionDoc = await sessionRef.get();
    const sessionData = sessionDoc.exists ? sessionDoc.data()! : {};

    const ts = admin.firestore.Timestamp.fromDate(nowPH); // Store as proper Timestamp
    const hour = nowPH.getUTCHours(); // Use UTC hours since we adjusted the time

    // Determine which session field to update
    let updatedField: "AMIn" | "AMOut" | "PMIn" | "PMOut" | null = null;

    if (hour < 12) {
      if (!sessionData.AMIn) {
        sessionData.AMIn = ts; // Store as proper Timestamp
        updatedField = "AMIn";
      } else {
        sessionData.AMOut = ts; // Store as proper Timestamp
        updatedField = "AMOut";
      }
    } else {
      if (!sessionData.PMIn) {
        sessionData.PMIn = ts; // Store as proper Timestamp
        updatedField = "PMIn";
      } else {
        sessionData.PMOut = ts; // Store as proper Timestamp
        updatedField = "PMOut";
      }
    }

    await sessionRef.set(sessionData, { merge: true });

    // 🔹 Send notification (if user has FCM token)
    if (matchedUser.data()?.fcmToken && updatedField) {
      const studentName = matchedCard.data()?.label || "Student";
      const displayTime = formatTimeForDisplay(nowPH);

      const statusMessageMap: Record<string, string> = {
        AMIn: "has arrived at school this morning",
        AMOut: "has left school this morning",
        PMIn: "has arrived at school this afternoon",
        PMOut: "has left school this afternoon",
      };

      await fcm.send({
        token: matchedUser.data()!.fcmToken,
        notification: {
          title: "MJL RFID",
          body: `${studentName} ${statusMessageMap[updatedField]} at ${displayTime}. Click to view details.`,
        },
        data: {
          uid: body.uid,
          macAddress: body.macAddress,
          session: updatedField,
        },
      });
    }

    return NextResponse.json({ success: true, saved: body }, { status: 200 });
  } catch (err) {
    console.error("❌ Error:", err);
    return NextResponse.json(
      { success: false, error: String(err) },
      { status: 400 }
    );
  }
}

// ✅ Helper: Format time for display (HH:MM AM/PM)
function formatTimeForDisplay(date: Date): string {
  let hours = date.getUTCHours();
  const minutes = date.getUTCMinutes();
  const period = hours >= 12 ? 'PM' : 'AM';
  
  hours = hours % 12;
  hours = hours ? hours : 12; // Convert 0 to 12
  
  return `${hours}:${minutes.toString().padStart(2, '0')} ${period}`;
}