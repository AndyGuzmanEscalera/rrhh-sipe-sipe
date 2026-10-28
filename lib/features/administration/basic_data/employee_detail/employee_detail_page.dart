import 'package:flutter/material.dart';
import 'package:failures/failures.dart';
import 'package:rrhh_repository/rrhh_repository.dart';
import 'package:rrhh_sipe_sipe/injection/get_it.dart';

class EmployeeDetailPage extends StatefulWidget {
  const EmployeeDetailPage({required this.employeeId, super.key});
  final String employeeId;
  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  late Future<Result<EmployeeAdmin, Failure>> _detail;
  @override
  void initState() {
    super.initState();
    _detail = sl<EmployeesAdminRepository>().get(widget.employeeId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detalle del funcionario')),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<Result<EmployeeAdmin, Failure>>(
                future: _detail,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  return snapshot.data!.when(
                    ok: (employee) => SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(employee.fullName,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          Text('CI: ${employee.documentNumber ?? 'Sin CI'}'),
                          Text('Unidad: ${employee.unitName ?? 'Sin unidad'}'),
                          Text(
                              'Cargo: ${employee.positionName ?? 'Sin cargo'}'),
                          Text('Correo: ${employee.email ?? 'Sin correo'}'),
                          Text('Teléfono: ${employee.phone ?? 'Sin teléfono'}'),
                          Text(
                              'Estado: ${employee.isActive ? 'Activo' : 'Inactivo'}'),
                        ])),
                    err: (failure) =>
                        Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(FailureGeneric.message(
                          failure: failure,
                          messageResult: 'No se pudo cargar el detalle.')),
                      TextButton(
                          onPressed: () => setState(() {
                                _detail = sl<EmployeesAdminRepository>()
                                    .get(widget.employeeId);
                              }),
                          child: const Text('Reintentar')),
                    ]),
                  );
                })),
      );
}
