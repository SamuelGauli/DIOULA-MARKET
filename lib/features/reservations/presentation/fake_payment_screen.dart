import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';

/// Faux écran de paiement (100 % **simulé**). Renvoie `true` au pop si le
/// « paiement » est validé. Aucune intégration réelle.
class FakePaymentScreen extends StatefulWidget {
  const FakePaymentScreen({super.key, required this.amount, required this.label});

  final double amount;
  final String label;

  @override
  State<FakePaymentScreen> createState() => _FakePaymentScreenState();
}

class _FakePaymentScreenState extends State<FakePaymentScreen> {
  final _number = TextEditingController(text: '4242 4242 4242 4242');
  final _exp = TextEditingController(text: '12/29');
  final _cvv = TextEditingController(text: '123');
  final _name = TextEditingController(text: 'CLIENT DEMO');
  bool _processing = false;

  @override
  void dispose() {
    _number.dispose();
    _exp.dispose();
    _cvv.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    context.pop(true); // paiement « réussi » (simulé)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement (simulé)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Carte « montant »
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Montant à payer',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(formatFcfa(widget.amount),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(widget.label,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _number,
            label: 'Numéro de carte',
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                    controller: _exp, label: 'Exp.', prefixIcon: Icons.event),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                    controller: _cvv, label: 'CVV', prefixIcon: Icons.lock),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _name,
            label: 'Titulaire',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Payer ${formatFcfa(widget.amount)}',
            icon: Icons.lock,
            gradient: true,
            loading: _processing,
            onPressed: _pay,
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.body),
              SizedBox(width: 6),
              Text('Paiement 100 % simulé — aucune transaction réelle.',
                  style: TextStyle(color: AppColors.body, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
