import { createClient } from '@supabase/supabase-js';
import admin from 'firebase-admin';

// Initialize Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// Initialize Firebase Admin
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { uid, macAddress } = req.body;
    
    // Validate input
    if (!uid || !macAddress) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Store the tap event in Supabase
    const { data: tapData, error: tapError } = await supabase
      .from('tap_events')
      .insert([{ card_uid: uid, mac_address: macAddress }]);

    if (tapError) {
      console.error('Error storing tap event:', tapError);
      return res.status(500).json({ error: 'Failed to store tap event' });
    }

    // Find the user associated with this RFID card
    const { data: cardData, error: cardError } = await supabase
      .from('rfid_cards')
      .select('user_id, name')
      .eq('uid', uid)
      .single();

    if (cardError || !cardData) {
      console.log('No user associated with this RFID card');
      return res.status(200).json({ message: 'Tap recorded but no user notification sent' });
    }

    // Get the user's FCM token
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', cardData.user_id)
      .single();

    if (userError || !userData || !userData.fcm_token) {
      console.log('No FCM token found for user');
      return res.status(200).json({ message: 'Tap recorded but no FCM token available' });
    }

    // Send push notification
    const message = {
      notification: {
        title: 'RFID Tap Detected',
        body: `Card "${cardData.name}" was tapped at ${new Date().toLocaleTimeString()}`
      },
      token: userData.fcm_token
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully');
    } catch (fcmError) {
      console.error('Error sending notification:', fcmError);
    }

    res.status(200).json({ message: 'Tap recorded and notification sent' });
  } catch (error) {
    console.error('Server error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}