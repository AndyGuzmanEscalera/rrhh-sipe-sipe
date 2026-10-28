import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../helpers/menu_options.dart';

part 'side_menu_state.dart';

class SideMenuCubit extends Cubit<SideMenuState> {
  SideMenuCubit() : super(const SideMenuState());

  void select(MenuOption menu) => emit(SideMenuState(selected: menu));
}
