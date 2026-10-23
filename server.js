const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/mre_livre_db',
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

// Base FAQ Bilingue IA
const FAQ_DATABASE = {
  FR: {
    paiement: "Paiements sécurisés via Mobile Money (T-Money, Flooz, Orange, MTN MoMo) ou QR Code à la livraison.",
    securite: "Suivi GPS en direct et bouton SOS connecté immédiatement aux secours et à l'administration.",
    commission: "La commission de la plateforme est de 12% à 18% par transaction.",
    roles: "L'application gère 4 rôles : Administration, Conducteurs/Livreurs, Clients, et Boutiques partenaires."
  },
  EN: {
    paiement: "Secure payments via Mobile Money (T-Money, Flooz, Orange, MTN MoMo) or QR Code upon delivery.",
    securite: "Live GPS tracking and SOS button connected directly to emergency services and admin.",
    commission: "Platform commission ranges between 12% and 18% per transaction.",
    roles: "The app supports 4 roles: Administration, Drivers/Delivery, Clients, and Partner Shops."
  }
};

app.get('/', (req, res) => {
  res.json({ message: "API Mr E LIVRÉ & TRANSPORT (Multi-Rôles Active)", status: "OK" });
});

// 1. ENDPOINT D'AUTHENTIFICATION & SÉLECTION DE RÔLE
app.post('/api/auth/login', async (req, res) => {
  const { phone, role } = req.body;
  res.json({
    success: true,
    user: {
      id: "usr-" + Date.now(),
      full_name: "Utilisateur Test",
      phone: phone || "+22890000000",
      role: role || "CLIENT"
    },
    token: "jwt-token-mre-2026"
  });
});

// 2. ENDPOINT ASSISTANT IA MR E & FAQ
app.post('/api/mre/consult', async (req, res) => {
  const { message, lang = 'FR', role = 'CLIENT' } = req.body;
  const prompt = (message || '').toLowerCase();
  const currentLang = FAQ_DATABASE[lang] ? lang : 'FR';

  let responseText = "";
  if (prompt.includes('pay') || prompt.includes('tmoney') || prompt.includes('flooz')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].paiement}`;
  } else if (prompt.includes('sos') || prompt.includes('danger') || prompt.includes('sécurité')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].securite}`;
  } else if (prompt.includes('role') || prompt.includes('compte') || prompt.includes('boutique')) {
    responseText = `Mr E (FAQ) : ${FAQ_DATABASE[currentLang].roles}`;
  } else {
    responseText = lang === 'FR' 
      ? `Mr E (${role}) : Bonjour ! Je suis votre assistant pour les livraisons, courses, gestion de stock et sécurité.`
      : `Mr E (${role}): Hello! I am your assistant for deliveries, rides, stock management, and safety.`;
  }

  res.json({ success: true, response: responseText });
});

// 3. ENDPOINT ESPACE CLIENT : Création de course ou commande
app.post('/api/client/orders', async (req, res) => {
  const { client_id, type, pickup, destination, amount, provider } = req.body;
  res.json({
    success: true,
    message: "Commande créée et transmise au conducteur le plus proche.",
    order: {
      order_id: "CMD-" + Date.now(),
      status: "PENDING",
      pickup,
      destination,
      amount,
      payment_provider: provider || "T-Money"
    }
  });
});

// 4. ENDPOINT ESPACE CONDUCTEUR : Statut en ligne et acceptation de course
app.post('/api/driver/toggle-status', async (req, res) => {
  const { driver_id, is_online, lat, lng } = req.body;
  res.json({ success: true, is_online: is_online, message: is_online ? "Vous êtes EN LIGNE" : "Vous êtes HORS LIGNE" });
});

// 5. ENDPOINT ESPACE BOUTIQUE : Gestion des stocks produits
app.get('/api/shop/inventory', async (req, res) => {
  res.json({
    success: true,
    inventory: [
      { id: "p1", product_name: "Riz 5kg", price: 4500, quantity: 15, status: "OK" },
      { id: "p2", product_name: "Huile 1L", price: 1200, quantity: 2, status: "LOW_STOCK" }
    ]
  });
});

// 6. ENDPOINT ESPACE ADMIN : Vue globale, transactions, SOS
app.get('/api/admin/dashboard', async (req, res) => {
  res.json({
    success: true,
    stats: {
      total_users: 1420,
      active_drivers: 85,
      active_shops: 42,
      total_commissions_fcfa: 485000,
      active_sos_alerts: 0
    }
  });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 Serveur Mr E Multi-Rôles sur le port ${PORT}`);
});
