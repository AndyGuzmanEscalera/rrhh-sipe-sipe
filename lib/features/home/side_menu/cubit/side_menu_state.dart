part of 'side_menu_cubit.dart';

class SideMenuState extends Equatable {
  const SideMenuState({this.selected = dashboardMenu});

  final MenuOption selected;

  @override
  List<Object?> get props => [selected.menu];
}
