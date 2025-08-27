// api/rfid.js - Vercel serverless (Node)
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

module.exports = async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).send('Method not allowed');

    // ESP posts 'application/x-www-form-urlencoded' containing: tpl=rf_id&data={"uid":"...","macAddress":"..."}
    const body = req.body || '';
    // If Vercel already parsed body, req.body might be object
    let payloadStr = '';
    if (typeof body === 'string') {
      // parse manually
      const params = new URLSearchParams(body);
      payloadStr = params.get('data') || '';
    } else {
      // body parsed as object by Vercel
      payloadStr = body.data || '';
    }

    if (!payloadStr) return res.status(400).send('missing data');

    const data = JSON.parse(payloadStr);
    const uid = (data.uid || '').trim();
    const mac = (data.macAddress || '').trim();

    const uid_normalized = uid.replace(/\s+/g, '').toLowerCase(); // normalize

    // Init Supabase
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE; // use service role key
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Try to find matching card
    const { data: cardRows, error } = await supabase
      .from('cards')
      .select('id, user_id, label')
      .eq('uid_normalized', uid_normalized);

    // Insert tap record
    await supabase.from('taps').insert({
      uid,
      uid_normalized,
      mac_address: mac,
      card_id: cardRows && cardRows.length ? cardRows[0].id : null
    });

    // Send notifications if owners found
    if (cardRows && cardRows.length) {
      // initialize firebase admin
      if (!admin.apps.length) {
        const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
        const cert = JSON.parse(serviceAccountJson);
        admin.initializeApp({
          credential: admin.credential.cert(cert)
        });
      }

      // for each owner, fetch device tokens and send FCM
      const tokensToNotify = [];
      for (const c of cardRows) {
        const { data: tokens } = await supabase
          .from('device_tokens')
          .select('token')
          .eq('user_id', c.user_id);
        if (tokens && tokens.length) tokens.forEach(t => tokensToNotify.push(t.token));
      }

      if (tokensToNotify.length) {
        const message = {
          notification: {
            title: 'RFID Tap detected',
            body: `${cardRows[0].label || uid} tapped at ${new Date().toLocaleString()}`
          }
        };
        const chunkSize = 500; // FCM limit
        for (let i = 0; i < tokensToNotify.length; i += chunkSize) {
          const chunk = tokensToNotify.slice(i, i + chunkSize);
          const resp = await admin.messaging().sendMulticast({ tokens: chunk, ...message });
          console.log('FCM result:', resp);
        }
      }
    }

    return res.status(200).send('ok');

  } catch (err) {
    console.error('rfid handler error', err);
    return res.status(500).send('server error');
  }
};
