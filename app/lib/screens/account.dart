import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../providers.dart';
import '../theme.dart';
import '../widgets.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: user.when(
        data: (u) => u == null
            ? const _LoginForm()
            : u.isPremium
                ? _PremiumAccount(user: u)
                : _FreeAccount(user: u),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(userProvider)),
      ),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();
  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      if (_registering) {
        await api.register(_email.text.trim(), _password.text);
      } else {
        await api.login(_email.text.trim(), _password.text);
      }
      ref.invalidate(userProvider);
    } on ApiException catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(_registering ? 'Criar conta' : 'Entrar',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        GoldTextField(
            controller: _email, label: 'E-mail', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: AppSpacing.md),
        GoldTextField(controller: _password, label: 'Senha (mín. 8 caracteres)', obscure: true),
        const SizedBox(height: AppSpacing.md),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(_error!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.downRed)),
          ),
        GoldButton(
          label: _busy ? 'Aguarde...' : (_registering ? 'Cadastrar' : 'Entrar'),
          onPressed: _busy ? null : _submit,
        ),
        TextButton(
          onPressed: () => setState(() => _registering = !_registering),
          child: Text(_registering ? 'Já tenho conta' : 'Criar conta nova'),
        ),
      ],
    );
  }
}

class _FreeAccount extends ConsumerWidget {
  final User user;
  const _FreeAccount({required this.user});

  static const _benefits = [
    'Alertas de preço com push notification',
    'Calculadora de investimento',
    'Análise técnica: médias móveis + RSI',
  ];

  Future<void> _checkout(BuildContext context, WidgetRef ref, String plan) async {
    try {
      final url = await ref.read(apiProvider).checkoutUrl(plan);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(user.email, style: text.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        Text('Seja Premium', style: text.headlineMedium?.copyWith(color: AppColors.goldPrimary)),
        const SizedBox(height: AppSpacing.md),
        for (final b in _benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              const Icon(Icons.check, size: 16, color: AppColors.upGreen),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(b, style: text.bodyMedium)),
            ]),
          ),
        const SizedBox(height: AppSpacing.lg),
        GoldButton(
            label: 'Mensal — R\$14,90/mês',
            onPressed: () => _checkout(context, ref, 'monthly')),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => _checkout(context, ref, 'annual'),
          child: const Text('Anual — R\$119,90/ano (~20% off)'),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: () async {
            await ref.read(apiProvider).logout();
            ref.invalidate(userProvider);
          },
          child: const Text('Sair'),
        ),
      ],
    );
  }
}

class _PremiumAccount extends ConsumerWidget {
  final User user;
  const _PremiumAccount({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(children: [
          const Icon(Icons.workspace_premium, color: AppColors.goldPrimary),
          const SizedBox(width: AppSpacing.sm),
          Text('Premium', style: text.titleMedium?.copyWith(color: AppColors.goldPrimary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(user.email, style: text.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        ListTile(
          title: const Text('Gerenciar assinatura'),
          subtitle: Text('Alterar plano ou cancelar', style: text.bodySmall),
          trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.textSecondary),
          // ponytail: abre portal do Stripe via link fixo de billing; trocar por
          // sessão do Customer Portal (POST /subscriptions/portal) quando existir.
          onTap: () => launchUrl(Uri.parse('https://billing.stripe.com/p/login/test'),
              mode: LaunchMode.externalApplication),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: () async {
            await ref.read(apiProvider).logout();
            ref.invalidate(userProvider);
          },
          child: const Text('Sair'),
        ),
      ],
    );
  }
}
