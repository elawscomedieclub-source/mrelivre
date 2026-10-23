const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Base de données FAQ intégrée
const FAQ_DATABASE = {
  FR: {
    paiement: "Les paiements s'effectuent en toute sécurité via Mobile Money (T-Money, Flooz, Orange Money, MTN MoMo) ou à la livraison avec validation par QR Code.",
    livraison: "Le livreur le plus proche de la boutique est automatiquement notifié dès qu'une commande est validée.",
    securite: "Chaque trajet et chaque livraison disposent d'un suivi GPS en direct et d'un bouton SOS d'urgence directement accessible sur l'application.",
    commission: "La plateforme prélève une commission transparente de 12% à 18% par course ou livraison validée."
  },
  EN: {
    paiement: "Payments are securely processed via Mobile Money (T-Money, Flooz, Orange Money, MTN MoMo) or upon delivery with QR Code validation.",
    livraison: "The nearest delivery driver is automatically notified as soon as an order is confirmed.",
    securite: "Every trip and delivery features live GPS tracking and an emergency SOS button directly available in the app.",
    commission: "The platform charges a transparent commission of 12% to 18% per completed ride or delivery."
  }
};

// PostgreSQL configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/mre_livre_db',
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

// Firebase Admin SDK (optionnel)
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log("🔥 Firebase Admin SDK initialisé.");
} catch (e) {
  console.log("ℹ️ Firebase Admin SDK non configuré.");
}

async function sendPushNotification(fcmToken, title, body, data = {}) {
  if (!admin.apps.length || !fcmToken) return { success: false, message: "FCM non prêt" };
  const message = { notification: { title, body }, data, token: fcmToken };
  try {
    const response = await admin.messaging().send(message);
    return { success: true, response };
  } catch (error) {
    console.error('Erreur Push FCM :', error);
    return { success: false, error };
  }
}

// Route d'accueil
app.get('/', (req, res) => {
  res.json({ message: "API Mr E LIVRÉ & TRANSPORT en ligne !", status: "OK" });
});

// Endpoint IA Mr E + FAQ
app.post('/api/mre/consult', async (req, res) => {
  const { message, lang = 'FR' } = req.body;
  const prompt = (message || '').toLowerCase();
  const currentLang = FAQ_DATABASE[lang] ? lang : 'FR';

  let responseText = '';
  let actionType = 'INFO';
  let payload = {};

  if (prompt.includes('pay') || prompt.includes('paiement') || prompt.includes('argent') || prompt.includes('tmoney') || prompt.includes('flooz')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].paiement}`;
  } else if (prompt.includes('livreur') || prompt.includes('livraison') || prompt.includes('commande')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].livraison}`;
  } else if (prompt.includes('sos') || prompt.includes('sécurité') || prompt.includes('danger') || prompt.includes('route')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].securite}`;
    actionType = 'SAFETY_ALERT';
  } else if (prompt.includes('commission') || prompt.includes('frais') || prompt.includes('prix')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].commission}`;
  } else if (prompt.includes('stock') || prompt.includes('rupture') || prompt.includes('boutique')) {
    actionType = 'STOCK_CHECK';
    try {
      const stockRes = await pool.query(
        `SELECT s.shop_name, i.product_name, i.quantity 
         FROM inventory i 
         JOIN shops s ON i.shop_id = s.id 
         WHERE i.quantity <= i.low_stock_threshold`
      );
      const items = stockRes.rows.map(r => `${r.product_name} (${r.shop_name}: ${r.quantity})`).join(', ');
      responseText = items.length > 0 
        ? (lang === 'FR' ? `Mr E : Alertes stock bas : ${items}` : `Mr E: Low stock alerts: ${items}`)
        : (lang === 'FR' ? "Mr E : Tous les stocks sont optimaux." : "Mr E: All stock levels are optimal.");
      payload = { items: stockRes.rows };
    } catch (err) {
      responseText = lang === 'FR' ? "Mr E : Surveillance des stocks active." : "Mr E: Stock monitoring active.";
    }
  } else {
    responseText = lang === 'FR'
      ? "Mr E : Bonjour ! Posez-moi vos questions sur les livraisons, le transport, la sécurité ou les paiements Mobile Money."
      : "Mr E: Hello! Ask me anything about deliveries, rides, safety, or Mobile Money payments.";
  }

  res.json({ success: true, response: responseText, action: actionType, payload });
});

// Création de commande
app.post('/api/orders/create', async (req, res) => {
  const { client_id, type, transport_mode, pickup, destination, fare_amount } = req.body;
  const qr_hash = `MRE-${Date.now()}-${Math.floor(Math.random() * 10000)}`;

  try {
    const result = await pool.query(
      `INSERT INTO rides_and_deliveries 
       (type, client_id, transport_mode, pickup_location, destination, fare_amount, qr_code_hash, status) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'PENDING') 
       RETURNING *`,
      [type || 'DELIVERY', client_id, transport_mode || 'MOTO', pickup, destination, fare_amount, qr_hash]
    );
    res.json({ success: true, message: "Demande créée avec succès.", order: result.rows[0] });
  } catch (err) {
    res.json({ success: true, message: "Commande enregistrée (mode simulation).", order: { qr_code_hash: qr_hash } });
  }
});

// Paiement Mobile Money
app.post('/api/payment/mobile-money', async (req, res) => {
  const { phone_number, amount, provider, order_id, driver_fcm_token, lang = 'FR' } = req.body;
  const transactionRef = `MRE-PAY-${Date.now()}`;

  if (driver_fcm_token) {
    await sendPushNotification(
      driver_fcm_token,
      lang === 'FR' ? '🚨 Nouvelle Course Payée !' : '🚨 New Paid Ride!',
      lang === 'FR' ? `Commande #${order_id} (${amount} FCFA). Touchez pour accepter.` : `Order #${order_id} (${amount} FCFA). Tap to accept.`
    );
  }

  res.json({
    success: true,
    transaction_ref: transactionRef,
    status: 'PENDING_USER_APPROVAL',
    message: lang === 'FR' 
      ? `Veuillez valider le paiement de ${amount} FCFA sur votre téléphone (${provider}).`
      : `Please confirm payment of ${amount} FCFA on your phone (${provider}).`
  });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 Serveur Mr E actif sur le port ${PORT}`);
});
