// lib/screens/dashboard_screen.dart — Tableau de bord bancaire
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/compte.dart';
import '../models/transaction.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/bank_card_widget.dart';
import '../widgets/transaction_tile.dart';
import 'login_screen.dart';
import 'chatbot_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService();

  List<Compte> _comptes = [];
  List<Transaction> _transactions = [];
  bool _loadingComptes = true;
  bool _loadingTx = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user!.id.toString();
    final token  = auth.token!;

    try {
      final comptes = await _api.fetchComptes(userId, token);
      final txs     = await _api.fetchTransactions(userId, token);
      if (mounted) {
        setState(() {
          _comptes      = comptes;
          _transactions = txs;
          _loadingComptes = false;
          _loadingTx    = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loadingComptes = false; _loadingTx = false; });
    }
  }

  double get _soldeTotal =>
      _comptes.fold(0, (sum, c) => sum + c.solde);

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fmtCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: const Color(0xFFC9A84C),
        foregroundColor: const Color(0xFF0A0F1E),
        icon: const Text('◈', style: TextStyle(fontSize: 18)),
        label: const Text('FinBot', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: RefreshIndicator(          onRefresh: _loadData,
          color: const Color(0xFFC9A84C),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(auth.user?.nom ?? 'Utilisateur'),
              ),

              // ── Stats ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildStatsRow(fmtCurrency),
                ),
              ),

              // ── Cartes ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'MES COMPTES',
                        style: TextStyle(
                          fontSize: 11, letterSpacing: 1.5,
                          color: Color(0xFF8892A4), fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _loadingComptes
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)))
                        : SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _comptes.length,
                              itemBuilder: (_, i) => BankCardWidget(compte: _comptes[i]),
                            ),
                          ),
                  ],
                ),
              ),

              // ── Transactions ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TRANSACTIONS RÉCENTES',
                        style: TextStyle(
                          fontSize: 11, letterSpacing: 1.5,
                          color: Color(0xFF8892A4), fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!_loadingTx)
                        Text(
                          '${_transactions.length} opérations',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF8892A4)),
                        ),
                    ],
                  ),
                ),
              ),

              if (_loadingTx)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => TransactionTile(transaction: _transactions[i]),
                      childCount: _transactions.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF141D2E),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2D45))),
      ),
      child: Row(
        children: [
          const Text('◈ ', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 18)),
          const Text('FinFlow', style: TextStyle(color: Color(0xFFC9A84C), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: const Color(0xFF1E2D45)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour,', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                Text(userName, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 14),
            label: const Text('Déconnexion', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Color(0xFF1E2D45)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(NumberFormat fmt) {
    return Row(
      children: [
        _statCard('Solde Total', fmt.format(_soldeTotal), null),
        const SizedBox(width: 8),
        _statCard('Entrées', '+3 200,00 €', const Color(0xFF22C983)),
        const SizedBox(width: 8),
        _statCard('Sorties', '-1 847,50 €', const Color(0xFFE05252)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color? valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141D2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1E2D45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 9, letterSpacing: 0.5, color: Color(0xFF8892A4)),
            ),
            const SizedBox(height: 4),
            Text(value,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
