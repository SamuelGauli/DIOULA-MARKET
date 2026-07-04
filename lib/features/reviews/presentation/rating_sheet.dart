import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'widgets/star_rating.dart';

/// Ouvre une feuille de notation (étoiles + commentaire) et renvoie `true`
/// si l'avis a bien été envoyé. [onSubmit] effectue l'insertion (et peut lever).
Future<bool?> showRatingSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Future<void> Function(int rating, String? comment) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _RatingSheet(title: title, subtitle: subtitle, onSubmit: onSubmit),
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({
    required this.title,
    required this.subtitle,
    required this.onSubmit,
  });

  final String title;
  final String? subtitle;
  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final text = _comment.text.trim();
      await widget.onSubmit(_rating, text.isEmpty ? null : text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.body, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          StarPicker(
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Ton commentaire (optionnel)…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_busy ? 'Envoi…' : 'Envoyer mon avis'),
          ),
        ],
      ),
    );
  }
}
