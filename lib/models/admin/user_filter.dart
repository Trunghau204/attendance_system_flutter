/// Filter options cho danh sách nhân viên
class UserFilter {
  final String? keyword;
  final int? departmentId;
  final bool? isActive;
  final String? role;
  final int page;
  final int pageSize;

  UserFilter({
    this.keyword,
    this.departmentId,
    this.isActive,
    this.role,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (keyword != null && keyword!.isNotEmpty) {
      params['keyword'] = keyword;
    }
    if (departmentId != null) {
      params['departmentId'] = departmentId;
    }
    if (isActive != null) {
      params['isActive'] = isActive;
    }
    if (role != null && role!.isNotEmpty) {
      params['role'] = role;
    }
    params['page'] = page;
    params['pageSize'] = pageSize;

    return params;
  }

  UserFilter copyWith({
    String? keyword,
    int? departmentId,
    bool? isActive,
    String? role,
    int? page,
    int? pageSize,
  }) {
    return UserFilter(
      keyword: keyword ?? this.keyword,
      departmentId: departmentId ?? this.departmentId,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Clear all filters
  UserFilter clear() {
    return UserFilter(page: 1, pageSize: pageSize);
  }

  /// Check if any filter is active
  bool get hasActiveFilter {
    return keyword != null ||
        departmentId != null ||
        isActive != null ||
        role != null;
  }
}
