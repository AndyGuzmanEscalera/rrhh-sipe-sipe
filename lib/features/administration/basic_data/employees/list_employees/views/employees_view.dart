import 'package:rrhh_sipe_sipe/core/helpers/full_widget_generics.dart';
import 'package:rrhh_sipe_sipe/core/util/enums.dart';
import 'package:rrhh_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:rrhh_sipe_sipe/features/administration/basic_data/employees/list_employees/views/employees_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EmployeesCubit, EmployeesState>(
          listenWhen: (previous, current) =>
              previous.generalStatus != current.generalStatus,
          listener: (context, state) {
            if (state.generalStatus == GeneralStatus.error ||
                (state.generalStatus == GeneralStatus.success &&
                    state.dialogMessage.showSuccess)) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.dialogMessage.message)));
            }
          },
        ),
      ],
      child: FullWidgetGeneric(
        onInit: () {
          context.read<EmployeesCubit>().get();
        },
        child: const EmployeesBody(),
      ),
    );
  }
}
