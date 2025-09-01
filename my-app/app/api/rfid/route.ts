import { NextResponse } from "next/server";
import { db, fcm, admin } from "@/lib/firebaseAdmin";

// ✅ Helper: get PH-local date & time as Date object
function getPhilippinesDate(): Date {
  const now = new Date();
  // Convert to PH timezone string
  const phString = now.toLocaleString("en-US", { timeZone: "Asia/Manila" });
  // Parse back to Date object
  return new Date(phString);
}

// ✅ Helper: Format date to string like "September 2, 2025 at 7:35:51 PM UTC+8"
function formatPhilippinesTimestamp(date: Date): string {
  const months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  
  const month = months[date.getMonth()];
  const day = date.getDate();
  const year = date.getFullYear();
  
  // Format time with AM/PM
  let hours = date.getHours();
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  
  const period = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  hours = hours ? hours : 12; // Convert 0 to 12
  
  return `${month} ${day}, ${year} at ${hours}:${minutes}:${seconds} ${period} UTC+8`;
}

export async function POST(req: Request) {
  try {
    const body = await req.json();

    // 🔹 PH-local date & time
    const nowPH = getPhilippinesDate();
    const yyyy = nowPH.getFullYear();
    const mm = String(nowPH.getMonth() + 1).padStart(2, "0");
    const dd = String(nowPH.getDate()).padStart(2, "0");

    // Save raw log
    await db.collection("rfidLogs").doc().set({
      ...body,
      // Store as Timestamp but now will appear like PH time
      timestamp: admin.firestore.Timestamp.fromDate(nowPH),
      localDate: `${yyyy}-${mm}-${dd}`,
      localTime: nowPH.toLocaleTimeString("en-PH", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
      }),
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

    const formattedTime = formatPhilippinesTimestamp(nowPH);
    const hour = nowPH.getHours();

    // Determine which session field to update
    let updatedField: "AMIn" | "AMOut" | "PMIn" | "PMOut" | null = null;

    if (hour < 12) {
      if (!sessionData.AMIn) {
        sessionData.AMIn = formattedTime; // Store as formatted string instead of Timestamp
        updatedField = "AMIn";
      } else {
        sessionData.AMOut = formattedTime; // Store as formatted string instead of Timestamp
        updatedField = "AMOut";
      }
    } else {
      if (!sessionData.PMIn) {
        sessionData.PMIn = formattedTime; // Store as formatted string instead of Timestamp
        updatedField = "PMIn";
      } else {
        sessionData.PMOut = formattedTime; // Store as formatted string instead of Timestamp
        updatedField = "PMOut";
      }
    }

    await sessionRef.set(sessionData, { merge: true });

    // 🔹 Send notification (if user has FCM token)
    if (matchedUser.data()?.fcmToken && updatedField) {
      const studentName = matchedCard.data()?.label || "Student";
      const displayTime = nowPH.toLocaleTimeString("en-PH", {
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
      });

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