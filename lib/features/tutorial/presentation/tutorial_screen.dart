import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/tutorial_step.dart';
import 'tutorial_provider.dart';

/// Mini-tutoriel affiché après l'inscription, **adapté au rôle**.
/// Accessible aussi depuis le profil (« Revoir le tutoriel »).
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key, this.role});

  /// Rôle forcé (ex: depuis le profil). Sinon on déduit du contexte.
  final UserRole? role;

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  UserRole _resolveRole() {
    return widget.role ??
        ref.read(pendingTutorialProvider) ??
        ref.read(currentProfileProvider).value?.role ??
        UserRole.consommateur;
  }

  void _finish() {
    ref.read(pendingTutorialProvider.notifier).set(null);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _resolveRole();
    final steps = tutorialStepsForRole(role);
    final isLast = _page == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Barre du haut : rôle + passer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text('Profil : ${role.label}'),
                    avatar: const Icon(Icons.badge_outlined, size: 16),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _StepView(step: steps[i]),
              ),
            ),
            // Indicateurs (points)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _page == i ? 22 : 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.green
                        : AppColors.body.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: PrimaryButton(
                label: isLast ? 'Commencer' : 'Suivant',
                icon: isLast ? Icons.check : Icons.arrow_forward,
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});
  final TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 72, color: AppColors.green),
          )
              .animate(key: ValueKey(step.title))
              .scaleXY(
                begin: 0.6,
                end: 1,
                duration: 450.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 250.ms),
          const SizedBox(height: 32),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.body, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
