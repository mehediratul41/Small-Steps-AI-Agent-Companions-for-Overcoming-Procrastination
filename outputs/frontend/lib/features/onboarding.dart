import '../l10n/strings.dart';
import '../app/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../app/config.dart';
import '../app/theme.dart';
import '../shared/widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: const [LanguageMenu()]),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (c.maxHeight - 64).clamp(0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 214,
                      height: 214,
                      decoration: BoxDecoration(
                        color: softColor(context, AppTokens.mint),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 106,
                          height: 106,
                          decoration: BoxDecoration(
                            color: AppTokens.teal,
                            borderRadius: BorderRadius.circular(35),
                          ),
                          child: const Center(
                            child: BrandSpark(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      context.l10n.smallSteps_01d07f,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.progressNotPressure_6bc048,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context
                          .l10n
                          .aGentleCompanionForMeaningfulManageable_d4b672,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    PrimaryButton(
                      context.l10n.getStarted_bd2cb0,
                      onPressed: () => context.go('/consent'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/consent'),
                      child: Text(context.l10n.exploreTheResearchDemo_beb40f),
                    ),
                    if (AppConfig.researcherDemo)
                      TextButton(
                        onPressed: () => context.go('/backend'),
                        child: Text(
                          context.l10n.connectToDevelopmentBackend_3ac1a0,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.shimaneUniversityHaiResearchPrototype_6f7a11,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});
  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool agreed = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: const [LanguageMenu()],
      leading: BackButton(onPressed: () => context.go('/welcome')),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: PageBody(
            children: [
              Heading(
                context.l10n.researchOnboarding_e8a35e,
                context.l10n.welcomeToTheStudy_3de6d2,
                context.l10n.pleaseReadTheInformationBelow_5fd5af,
              ),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.whatAreWeStudying_505e74,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(context.l10n.weAreExploringHowDifferentTypes_6e615d),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),
                    Text(
                      context.l10n.yourParticipation_1dcf8a,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ref.watch(appProvider).connected
                          ? context
                                .l10n
                                .thisIsAConnectedDevelopmentDemonstration_759c09
                          : context.l10n.participationIsVoluntaryThisIsA_11d758,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Chip(
                label: Text(
                  ref.watch(appProvider).connected
                      ? context.l10n.developmentId_163c4e(
                          (ref.watch(appProvider).backendId).toString(),
                        )
                      : context.l10n.demoResearchIdDemoP_992c84,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: agreed,
                onChanged: (v) => setState(() => agreed = v ?? false),
                title: Text(context.l10n.iHaveReadAndUnderstandThe_52762c),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                context.l10n.agreeContinue_684047,
                onPressed: agreed
                    ? () => perform(
                        context,
                        () => ref.read(appProvider.notifier).acceptConsent(),
                      )
                    : null,
              ),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      context.l10n.privacyDemonstrationConsent_84c5c7,
                    ),
                    content: SingleChildScrollView(
                      child: Text(
                        ref.read(appProvider).connected
                            ? context
                                  .l10n
                                  .connectedDevelopmentUsesASyntheticAccount_13f12b
                            : context
                                  .l10n
                                  .thisAcknowledgmentDemonstratesTheOnboardingInteraction_7acce1,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.close_bbfa77),
                      ),
                    ],
                  ),
                ),
                child: Text(context.l10n.readPrivacyAndConsentDetails_b80cfd),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
