import { NextResponse } from "next/server";
import { db, fcm, admin } from "@/lib/firebaseAdmin";

export async function POST(req: Request) {
  try {
    const body = await req.json(); // { uid, macAddress }
    console.log("📡 RFID Data:", body);

    // 1. Always save raw log
    const docRef = db.collection("rfidLogs").doc();
    await docRef.set({
      ...body,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 2. Find the user who owns this card
    const usersRef = db.collection("users");
    const usersSnap = await usersRef.get();

    let matchedUser: FirebaseFirestore.DocumentSnapshot | null = null;
    let matchedCard: FirebaseFirestore.DocumentSnapshot | null = null;

    for (const userDoc of usersSnap.docs) {
      const idsRef = userDoc.ref.collection("ids");
      const cardSnap = await idsRef.where("id", "==", body.uid).get();

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

    const userData = matchedUser.data();
    const cardData = matchedCard.data();
    const now = new Date();

    // 3. Work out today’s session doc in a top-level "rfidSessions" collection
    const yyyy = now.getFullYear();
    const mm = String(now.getMonth() + 1).padStart(2, "0");
    const dd = String(now.getDate()).padStart(2, "0");
    const todayId = `${yyyy}-${mm}-${dd}`;

    // Each day is a document, each card UID is a subdoc
    const sessionRef = db
      .collection("rfidSessions")
      .doc(todayId)
      .collection("cards")
      .doc(body.uid);

    const sessionDoc = await sessionRef.get();
    let sessionData: any = sessionDoc.exists ? sessionDoc.data() : {};

    const ts = admin.firestore.Timestamp.fromDate(now);
    const hour = now.getHours();

    if (hour < 12) {
      // AM range
      if (!sessionData.AMIn) {
        sessionData.AMIn = ts;
      } else {
        sessionData.AMOut = ts; // replace with latest
      }
    } else {
      // PM range
      if (!sessionData.PMIn) {
        sessionData.PMIn = ts;
      } else {
        sessionData.PMOut = ts; // replace with latest
      }
    }

    await sessionRef.set(sessionData, { merge: true });

    // 4. Send FCM notification to parent device
    if (userData?.fcmToken) {
      const studentName = cardData?.label || "Student";
      const formattedTime = now.toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
      });

      await fcm.send({
        token: userData.fcmToken,
        notification: {
          title: "Student Tap",
          body: `${studentName} has arrived at school at ${formattedTime}. Swipe to view details.`,
        },
        data: {
          uid: body.uid,
          macAddress: body.macAddress,
        },
      });

      console.log(`✅ Notification sent to ${userData.username || userData.email}`);
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
