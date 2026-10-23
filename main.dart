import 'package:flutter/material.dart';

void main() {
  runApp(const MrELivreMultiRoleApp());
}

class MrELivreMultiRoleApp extends StatefulWidget {
  const MrELivreMultiRoleApp({Key? key}) : super(key: key);

  @override
  State<MrELivreMultiRoleApp> createState() => _MrELivreMultiRoleAppState();
}

class _MrELivreMultiRoleAppState extends State<MrELivreMultiRoleApp> {
  // Rôles : 'CLIENT', 'DRIVER', 'SHOP', 'ADMIN'
  String _selectedRole = 'CLIENT';
  String _language = 'FR';
  bool _isDriverOnline = false;

  void _switchRole(String newRole) {
    setState(() {
      _selectedRole = newRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFr = _language == 'FR';

    return MaterialApp(
      title: 'Mr E LIVRÉ & TRANSPORT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Mr E (${_getRoleLabel(_selectedRole)})',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.switch_account, color: Colors.white),
              onSelected: _switchRole,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'CLIENT', child: Text('👤 Espace Client')),
                const PopupMenuItem(value: 'DRIVER', child: Text('🛵 Espace Conducteur')),
                const PopupMenuItem(value: 'SHOP', child: Text('🏪 Espace Boutique')),
                const PopupMenuItem(value: 'ADMIN', child: Text('⚙️ Espace Admin')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.sos, color: Colors.redAccent, size: 28),
              onPressed: () => _showSOSDialog(context),
            ),
          ],
        ),
        body: _buildRoleBody(isFr),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _getRoleIndex(_selectedRole),
          onTap: (index) {
            final roles = ['CLIENT', 'DRIVER', 'SHOP', 'ADMIN'];
            _switchRole(roles[index]);
          },
          selectedItemColor: const Color(0xFF2563EB),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Client'),
            BottomNavigationBarItem(icon: Icon(Icons.two_wheeler), label: 'Chauffeur'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Boutique'),
            BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'DRIVER': return 'Conducteur';
      case 'SHOP': return 'Boutique';
      case 'ADMIN': return 'Administration';
      default: return 'Client';
    }
  }

  int _getRoleIndex(String role) {
    switch (role) {
      case 'DRIVER': return 1;
      case 'SHOP': return 2;
      case 'ADMIN': return 3;
      default: return 0;
    }
  }

  Widget _buildRoleBody(bool isFr) {
    switch (_selectedRole) {
      case 'DRIVER': return _buildDriverScreen(isFr);
      case 'SHOP': return _buildShopScreen(isFr);
      case 'ADMIN': return _buildAdminScreen(isFr);
      default: return _buildClientScreen(isFr);
    }
  }

  // 1. ESPACE CLIENT
  Widget _buildClientScreen(bool isFr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('🛵 Commander une Course / Livraison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  const TextField(decoration: InputDecoration(labelText: 'Lieu de départ', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  const TextField(decoration: InputDecoration(labelText: 'Destination', border: OutlineInputBorder())),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    child: const Text('Payer par Mobile Money (T-Money / Flooz)'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 2. ESPACE CONDUCTEUR / LIVREUR
  Widget _buildDriverScreen(bool isFr) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(_isDriverOnline ? 'STATUT : EN LIGNE' : 'STATUT : HORS LIGNE', style: const TextStyle(fontWeight: FontWeight.bold)),
            value: _isDriverOnline,
            activeColor: Colors.green,
            onChanged: (val) => setState(() => _isDriverOnline = val),
          ),
          const Divider(),
          const Text('Demandes de Courses à proximité', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.two_wheeler, color: Colors.blue),
                    title: const Text('Livraison : Marché ➔ Tokoin'),
                    subtitle: const Text('1 500 FCFA'),
                    trailing: ElevatedButton(onPressed: () {}, child: const Text('Accepter')),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // 3. ESPACE BOUTIQUE PARTENAIRE
  Widget _buildShopScreen(bool isFr) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏪 Gestion de l'Inventaire Boutique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text('Riz 5kg'),
                  subtitle: Text('4 500 FCFA - Stock: 15'),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
                ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text('Huile 1L'),
                  subtitle: Text('1 200 FCFA - Stock: 2'),
                  trailing: Icon(Icons.warning, color: Colors.red),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 4. ESPACE ADMINISTRATION
  Widget _buildAdminScreen(bool isFr) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('⚙️ Super-Admin Mr E', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAdminStat('Drivers', '85'),
              _buildAdminStat('Shops', '42'),
              _buildAdminStat('Commissions', '485K'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAdminStat(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 ALERTE SOS', style: TextStyle(color: Colors.red)),
        content: const Text('Position GPS transmise aux secours et au centre de contrôle Admin.'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }
}
