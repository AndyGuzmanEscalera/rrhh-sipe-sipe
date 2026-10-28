import 'package:flutter_bloc/flutter_bloc.dart';
import '../side_menu/cubit/side_menu_cubit.dart';
import 'package:rrhh_sipe_sipe/core/app/app_identity.dart';
import '../side_menu/helpers/menu_options.dart';
import 'package:flutter/material.dart';
import 'package:rrhh_sipe_sipe/core/theme/ui_colors.dart';

class HomeBrandMark extends StatelessWidget {
  const HomeBrandMark({this.size = 44, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: UiColors.primary, borderRadius: BorderRadius.circular(14)),
      child: Icon(Icons.people_alt_rounded,
          color: Colors.white, size: size * .55));
}

class HomeSidebar extends StatelessWidget {
  const HomeSidebar(
      {required this.onAccount, this.inDrawer = false, super.key});
  final VoidCallback onAccount;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final selected =
        context.select((SideMenuCubit cubit) => cubit.state.selected.menu);
    return Container(
        width: inDrawer ? 280 : 244,
        color: UiColors.sidebar,
        child: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const HomeBrandMark(),
                      const SizedBox(height: 20),
                      const Text(AppIdentity.name,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.2,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 32),
                      const Text('ESPACIO DE TRABAJO',
                          style: TextStyle(
                              color: UiColors.textOnDarkMuted,
                              fontSize: 10,
                              letterSpacing: 1.3)),
                      const SizedBox(height: 16),
                      ...menuOptions.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  selected: selected == option.menu,
                                  selectedTileColor: UiColors.sidebarActive,
                                  selectedColor: Colors.white,
                                  textColor: UiColors.textOnDarkMuted,
                                  iconColor: UiColors.textOnDarkMuted,
                                  leading: Icon(option.icon, size: 20),
                                  title: Text(option.label,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  onTap: () {
                                    if (inDrawer) Navigator.pop(context);
                                    context
                                        .read<SideMenuCubit>()
                                        .select(option);
                                  })))),
                      const SizedBox(height: 16),
                      TextButton.icon(
                          onPressed: () {
                            if (inDrawer) Navigator.pop(context);
                            onAccount();
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: UiColors.textOnDarkMuted),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text('Mi cuenta')),
                      const SizedBox(height: 32),
                      const Divider(color: UiColors.sidebarHover),
                      const SizedBox(height: 16),
                      const Text(AppIdentity.institution,
                          style: TextStyle(
                              color: UiColors.textOnDarkMuted,
                              fontSize: 12,
                              height: 1.6)),
                    ]))));
  }
}

class HomeWelcome extends StatelessWidget {
  const HomeWelcome({required this.username, required this.compact, super.key});
  final String username;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 24 : 36),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UiColors.heroStart,
                UiColors.heroMid,
                UiColors.heroEnd
              ])),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('PORTAL INSTITUCIONAL',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600))),
          const SizedBox(height: 22),
          Text('Bienvenido, $username',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 34,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7)),
          const SizedBox(height: 12),
          Text('Las personas, en el centro de nuestra gestión.',
              style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: compact ? 14 : 16,
                  height: 1.6)),
          const SizedBox(height: 22),
          const Row(children: [
            Icon(Icons.circle, color: Color(0xFF86EFAC), size: 7),
            SizedBox(width: 8),
            Text('Sesión iniciada',
                style: TextStyle(color: Colors.white, fontSize: 12))
          ]),
        ])),
        if (!compact) ...[
          const SizedBox(width: 20),
          Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.08),
                  border: Border.all(
                      color: Colors.white.withOpacity(.15), width: 12)),
              child: const Icon(Icons.diversity_3_outlined,
                  color: Colors.white, size: 48)),
        ],
      ]));
}

class HomeInfoCard extends StatelessWidget {
  const HomeInfoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.detail,
      required this.color,
      required this.background,
      super.key});
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: UiColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: UiColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: background, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color)),
          const Spacer(),
          Text(label,
              style: const TextStyle(
                  color: UiColors.textSecondary,
                  letterSpacing: 1.3,
                  fontSize: 10,
                  fontWeight: FontWeight.w600))
        ]),
        const SizedBox(height: 20),
        Text(value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        const SizedBox(height: 8),
        Text(detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: UiColors.textSecondary, fontSize: 12, height: 1.5)),
      ]));
}
