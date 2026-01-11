import 'package:flutter/material.dart';
import '../../../models/admin/user_management.dart';
import '../../../models/admin/user_filter.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';
import '../../../widgets/admin/user_card.dart';
import 'user_form_dialog.dart';

/// Màn hình quản lý danh sách nhân viên
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<UserManagement> _users = [];
  UserFilter _filter = UserFilter();
  bool _isLoading = false;
  int _totalCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load danh sách user từ API
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getUsers(_filter);
      setState(() {
        // Filter out admin users - only show regular users
        final allUsers = response['items'] as List<UserManagement>;
        _users = allUsers
            .where(
              (user) =>
                  user.roles.every((role) => role.toLowerCase() != 'admin'),
            )
            .toList();
        _totalCount = _users.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Search user
  void _onSearch(String keyword) {
    setState(() {
      _filter = _filter.copyWith(keyword: keyword, page: 1);
    });
    _loadUsers();
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  /// Filter bottom sheet
  Widget _buildFilterSheet() {
    UserFilter tempFilter = _filter;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lọc nhân viên',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status filter
              const Text(
                'Trạng thái',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: tempFilter.isActive == null,
                    onSelected: (selected) {
                      setModalState(() {
                        tempFilter = tempFilter.copyWith(isActive: null);
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Đang hoạt động'),
                    selected: tempFilter.isActive == true,
                    onSelected: (selected) {
                      setModalState(() {
                        tempFilter = tempFilter.copyWith(isActive: true);
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Đã khóa'),
                    selected: tempFilter.isActive == false,
                    onSelected: (selected) {
                      setModalState(() {
                        tempFilter = tempFilter.copyWith(isActive: false);
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Role filter
              const Text(
                'Vai trò',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: tempFilter.role == null,
                    onSelected: (selected) {
                      setModalState(() {
                        tempFilter = tempFilter.copyWith(role: null);
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Admin'),
                    selected: tempFilter.role == 'Admin',
                    onSelected: (selected) {
                      setModalState(() {
                        tempFilter = tempFilter.copyWith(role: 'Admin');
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('User'),
                    selected: tempFilter.role == 'User',
                    onSelected: (selected) {
                      setModalState(() {
                        tempFilter = tempFilter.copyWith(role: 'User');
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          tempFilter = tempFilter.clear();
                        });
                      },
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filter = tempFilter.copyWith(page: 1);
                        });
                        Navigator.pop(context);
                        _loadUsers();
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show create/edit dialog
  void _showUserFormDialog({UserManagement? user}) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    ).then((result) {
      if (result == true) {
        _loadUsers();
      }
    });
  }

  /// Delete user
  Future<void> _deleteUser(UserManagement user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhân viên ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa nhân viên thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Toggle user status (lock/unlock)
  Future<void> _toggleUserStatus(UserManagement user) async {
    final action = user.isActive ? 'khóa' : 'mở khóa';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text('Bạn có chắc muốn $action tài khoản ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      setState(() => _isLoading = true);

      await _apiService.toggleUserStatus(user.id);

      // Wait a bit for backend to process
      await Future.delayed(const Duration(milliseconds: 300));

      // Reload users để refresh trạng thái
      await _loadUsers();

      if (mounted) {
        final newStatus = !user.isActive; // Trạng thái sau khi toggle
        final actionMsg = newStatus ? 'Mở khóa' : 'Khóa';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionMsg tài khoản thành công'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Load next page
  void _loadNextPage() {
    if (_filter.page * _filter.pageSize >= _totalCount) return;

    setState(() {
      _filter = _filter.copyWith(page: _filter.page + 1);
    });
    _loadUsers();
  }

  /// Load previous page
  void _loadPreviousPage() {
    if (_filter.page <= 1) return;

    setState(() {
      _filter = _filter.copyWith(page: _filter.page - 1);
    });
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhân viên'),
        actions: [
          // Filter badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_filter.hasActiveFilter)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _onSearch,
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhân viên'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUsers, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _filter.hasActiveFilter
                  ? 'Không tìm thấy nhân viên nào'
                  : 'Chưa có nhân viên',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // User count
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              Text(
                'Tổng số: $_totalCount nhân viên',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // User list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return UserCard(
                  user: user,
                  onEdit: () => _showUserFormDialog(user: user),
                  onDelete: () => _deleteUser(user),
                  onToggleStatus: () => _toggleUserStatus(user),
                );
              },
            ),
          ),
        ),

        // Pagination
        if (_totalCount > _filter.pageSize)
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _filter.page > 1 ? _loadPreviousPage : null,
                ),
                Text(
                  'Trang ${_filter.page} / ${(_totalCount / _filter.pageSize).ceil()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _filter.page * _filter.pageSize < _totalCount
                      ? _loadNextPage
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
