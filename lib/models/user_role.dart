class UserRole {
  static const int customer = 1; // 'user' in DB
  static const int developer = 2; // 'admin' in DB
  static const int manager = 3; // 'manager' in DB
  static const int chef = 4; // 'chef' in DB

  static String getName(int roleId) {
    switch (roleId) {
      case customer:
        return 'Customer';
      case developer:
        return 'Developer';
      case manager:
        return 'Manager';
      case chef:
        return 'Chef';
      default:
        return 'Unknown';
    }
  }

  static bool isManager(int? roleId) => roleId == manager;
  static bool isDeveloper(int? roleId) => roleId == developer;
  static bool isCustomer(int? roleId) => roleId == customer;
}
