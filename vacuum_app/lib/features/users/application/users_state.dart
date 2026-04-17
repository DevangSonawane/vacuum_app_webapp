import '../domain/app_user.dart';

class UsersState {
  const UsersState({
    required this.users,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<AppUser> users;
  final int page;
  final int totalPages;
  final int total;

  UsersState copyWith({
    List<AppUser>? users,
    int? page,
    int? totalPages,
    int? total,
  }) {
    return UsersState(
      users: users ?? this.users,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
    );
  }

  static const empty = UsersState(users: [], page: 1, totalPages: 1, total: 0);
}

