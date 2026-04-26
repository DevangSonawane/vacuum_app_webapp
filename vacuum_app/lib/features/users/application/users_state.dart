import '../domain/app_user.dart';

class UsersState {
  const UsersState({
    required this.allUsers,
    required this.users,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.query,
  });

  final List<AppUser> allUsers;
  final List<AppUser> users;
  final int page;
  final int totalPages;
  final int total;
  final String query;

  UsersState copyWith({
    List<AppUser>? allUsers,
    List<AppUser>? users,
    int? page,
    int? totalPages,
    int? total,
    String? query,
  }) {
    return UsersState(
      allUsers: allUsers ?? this.allUsers,
      users: users ?? this.users,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      query: query ?? this.query,
    );
  }

  static const empty = UsersState(
    allUsers: [],
    users: [],
    page: 1,
    totalPages: 1,
    total: 0,
    query: '',
  );
}
