class RoleConstants {
  static const int admin = 1;
  static const int customer = 2;
  static const int hotelOwner = 3;
  static const int travelAgent = 4;
}

String routeByRole({
  required String? roleId,
  String? roleName,
}) {
  final parsedRoleId = int.tryParse((roleId ?? '').trim());
  switch (parsedRoleId) {
    case RoleConstants.admin:
      return '/admin_dashboard';
    case RoleConstants.customer:
      return '/home';
    case RoleConstants.hotelOwner:
      return '/hotel_dashboard';
    case RoleConstants.travelAgent:
      return '/agent_dashboard';
  }

  final normalizedRoleName = (roleName ?? '').toUpperCase().trim();
  if (normalizedRoleName == 'ADMIN') return '/admin_dashboard';
  if (normalizedRoleName == 'CUSTOMER') return '/home';
  if (normalizedRoleName == 'HOTEL_OWNER' ||
      normalizedRoleName == 'HOTEL_PARTNER') {
    return '/hotel_dashboard';
  }
  if (normalizedRoleName == 'TRAVEL_AGENT' ||
      normalizedRoleName == 'AGENT' ||
      normalizedRoleName == 'BUS_PARTNER' ||
      normalizedRoleName == 'BUS_OWNER') {
    return '/agent_dashboard';
  }
  return '/home';
}
