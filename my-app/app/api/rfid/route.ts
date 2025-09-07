import { NextResponse } from "next/server";
import { db, fcm, admin } from "@/lib/firebaseAdmin";
import { format, toZonedTime } from "date-fns-tz";

// ✅ Helper: get PH-local date & time
function getPhilippinesNow() {
  const nowUTC = new Date(); // current UTC
  const nowPH = toZonedTime(nowUTC, "Asia/Manila");

  return {
    utc: nowUTC,   // safe for Firestore
    zoned: nowPH,  // PH local representation
  };
}

// ✅ Helper: Convert PH-local Date to Firestore Timestamp that looks PH-correct
function philippineTimestamp(datePH: Date) {
  // Shift by -8 hours so Firestore UTC = PH local
  const shifted = new Date(datePH.getTime() - 8 * 60 * 60 * 1000);
  return admin.firestore.Timestamp.fromDate(shifted);
}

export async function POST(req: Request) {
  try {
    const body = await req.json();

    // 🔹 Get both UTC + PH times
    const { utc, zoned } = getPhilippinesNow();

    // For IDs & display fields
    const phDate = format(zoned, "yyyy-MM-dd", { timeZone: "Asia/Manila" });
    const phTime = format(zoned, "hh:mm a", { timeZone: "Asia/Manila" });

    // 🔹 Save raw log - store proper UTC + display fields
    await db.collection("rfidLogs").doc().set({
      ...body,
      timestamp: admin.firestore.Timestamp.fromDate(utc), // UTC safe
      localDate: phDate,
      localTime: phTime,
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

    // 🔹 Prepare session document - use PH date for document ID
    const todayId = phDate;
    const sessionRef = db
      .collection("rfidSessions")
      .doc(todayId)
      .collection("cards")
      .doc(body.uid);

    const sessionDoc = await sessionRef.get();
    const sessionData = sessionDoc.exists ? sessionDoc.data()! : {};

    // ✅ Store PH-correct timestamp
    const ts = philippineTimestamp(zoned);

    // Get PH hour for AM/PM classification
    const hour = parseInt(format(zoned, "H", { timeZone: "Asia/Manila" }));

    // Determine which session field to update
    let updatedField: "AMIn" | "AMOut" | "PMIn" | "PMOut" | null = null;

    if (hour < 12) {
      if (!sessionData.AMIn) {
        sessionData.AMIn = ts;
        updatedField = "AMIn";
      } else {
        sessionData.AMOut = ts;
        updatedField = "AMOut";
      }
    } else {
      if (!sessionData.PMIn) {
        sessionData.PMIn = ts;
        updatedField = "PMIn";
      } else {
        sessionData.PMOut = ts;
        updatedField = "PMOut";
      }
    }

    await sessionRef.set(sessionData, { merge: true });

    // 🔹 Send notification (if user has FCM token)
    if (matchedUser.data()?.fcmToken && updatedField) {
      const studentName = matchedCard.data()?.label || "Student";
      const displayTime = format(zoned, "hh:mm a", { timeZone: "Asia/Manila" });

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
