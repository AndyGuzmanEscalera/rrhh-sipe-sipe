/// HTTP layer: Dio, ApiMethod, endpoints, auth interceptors, and feature APIs.
///
/// All HTTP access in the app goes through this package's [ApiMethod].
/// The auth feature ([AuthenticationApi]) uses two Dio instances to avoid
/// the refresh-token recursion loop:
///   * `mainDio` — carries Authorization Bearer + the refresh interceptor.
///   * `refreshDio` — no Authorization, no refresh interceptor; used only for
///     login / refresh / logout so a 401 there cannot trigger another refresh.
library rrhh_api;

export 'src/features/attendance/api/attendance_api.dart';

export 'src/features/biometric_import/api/biometric_import_api.dart';

export 'src/features/organization/api/employees_admin_api.dart';
export 'src/features/organization/api/organizational_units_admin_api.dart';
export 'src/features/organization/api/positions_admin_api.dart';
export 'src/features/organization/models/employee_admin_response.dart';
export 'src/features/organization/models/organizational_unit_admin_response.dart';
export 'src/features/organization/models/position_admin_response.dart';

export 'src/core/network/network.dart';
export 'src/core/network/api_client.dart';
export 'src/core/network/api_config.dart';
export 'src/core/network/api_interceptor.dart';
export 'src/core/network/api_logger.dart';
export 'src/core/network/api_method.dart';
export 'src/core/network/auth_interceptor.dart';
export 'src/core/network/auth_refresh_coordinator.dart';
export 'src/core/network/auth_refresh_interceptor.dart';
export 'src/core/network/auth_token_store.dart';
export 'src/core/models/active_toggle_request.dart';
export 'src/core/models/paginated_response.dart';
export 'src/core/network/endpoints.dart';
export 'src/features/authentication/api/auth_api.dart';
export 'src/features/authentication/api/auth_remote.dart';
export 'src/features/authentication/authentication.dart';
export 'src/features/authentication/models/auth_response.dart';
export 'src/features/authentication/models/me_employee_response.dart';
export 'src/features/authentication/models/user_response.dart';
