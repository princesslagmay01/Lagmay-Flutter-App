import 'package:flutter/material.dart';
import 'screens.dart';
import '../services/services.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _primary = Color(0xFF00796B); // Teal
  static const _background = Color(0xFFF0F4F8); // Light grey-blue
  static const _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const GradesScreen(),
      const MyTasksScreen(), // Replaced TodoScreen
      _ProfileScreen(onLogout: _handleLogout),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: _surface,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: _primary,
          unselectedItemColor: Colors.black45,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Grades',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box_outlined),
              activeIcon: Icon(Icons.check_box_rounded),
              label: 'My Tasks', // Renamed label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Color(0xFF263238), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Color(0xFF78909C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF78909C)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

// ── Profile Screen ────────────────────────────────────────────────────────────

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.onLogout});
  final VoidCallback onLogout;

  static const _primary = Color(0xFF00796B); // Teal
  static const _background = Color(0xFFF0F4F8); // Light grey-blue
  static const _surface = Colors.white;
  static const _textDark = Color(0xFF263238);
  static const _textLight = Color(0xFF78909C);

  // 15 built-in avatars using Material Icons
  static const _avatars = [
    ('avatar_01', Icons.face_rounded),
    ('avatar_02', Icons.face_2_rounded),
    ('avatar_03', Icons.face_3_rounded),
    ('avatar_04', Icons.face_4_rounded),
    ('avatar_05', Icons.face_5_rounded),
    ('avatar_06', Icons.face_6_rounded),
    ('avatar_07', Icons.catching_pokemon_rounded),
    ('avatar_08', Icons.smart_toy_rounded),
    ('avatar_09', Icons.sentiment_very_satisfied_rounded),
    ('avatar_10', Icons.pets_rounded),
    ('avatar_11', Icons.emoji_nature_rounded),
    ('avatar_12', Icons.local_fire_department_rounded),
    ('avatar_13', Icons.star_rounded),
    ('avatar_14', Icons.bolt_rounded),
    ('avatar_15', Icons.rocket_launch_rounded),
  ];

  static IconData _iconForAvatar(String avatarId) {
    for (final a in _avatars) {
      if (a.$1 == avatarId) return a.$2;
    }
    return Icons.face_rounded;
  }

  void _showAvatarPicker(BuildContext context, String currentAvatarId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Avatar',
              style: TextStyle(
                color: _textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              itemCount: _avatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (ctx, i) {
                final avatar = _avatars[i];
                final isSelected = avatar.$1 == currentAvatarId;
                return GestureDetector(
                  onTap: () {
                    ProfileService().updateAvatar(avatar.$1);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? _primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      avatar.$2,
                      color: isSelected ? _primary : _textLight,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Offline check for profile
    final authService = AuthService();
    final offlineUser = authService.offlineUser;

    return StreamBuilder<UserProfile?>(
      stream: ProfileService().getProfile(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final name = profile?.name ?? offlineUser?['name'] ?? 'Loading...';
        final section = profile?.section ?? offlineUser?['section'] ?? '';
        final idNumber = profile?.idNumber ?? offlineUser?['id_number'] ?? '—';
        final email = authService.currentUser?.email ?? offlineUser?['email'] ?? '';
        final avatarId = profile?.avatarId ?? offlineUser?['avatar_id'] ?? 'avatar_01';

        return StreamBuilder<List<Todo>>(
          stream: TodoService().todosStream,
          initialData: TodoService().cachedTodos,
          builder: (context, todoSnap) {
            final todos = todoSnap.data ?? [];
            final completedAll = todos.where((t) => t.isDone && !t.isDeleted).length;

            return Scaffold(
              backgroundColor: _background,
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // ── Hero Section ──
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: () => _showAvatarPicker(context, avatarId),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: _primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _primary, width: 2.5),
                                    ),
                                    child: Icon(
                                      _iconForAvatar(avatarId),
                                      color: _primary,
                                      size: 52,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _surface, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name
                            Text(
                              name,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: _textLight,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Info Cards ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _InfoCard(
                              icon: Icons.numbers_rounded,
                              label: 'Student ID',
                              value: idNumber,
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.groups_outlined,
                              label: 'Section',
                              value: section,
                            ),
                            const SizedBox(height: 12),
                            _InfoCard(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: email,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── Stats ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_rounded,
                                label: 'Tasks Done\n(All-Time)',
                                value: completedAll.toString(),
                                color: const Color(0xFF43A047),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.pending_actions_rounded,
                                label: 'Tasks Still\nActive',
                                value: todos.where((t) => !t.isDone && !t.isDeleted).length.toString(),
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // ── Edit Profile & Logout Buttons ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showEditProfileDialog(context, profile ?? UserProfile(id: '', name: name, idNumber: idNumber, section: section, createdAt: DateTime.now())),
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit Info'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary.withValues(alpha: 0.1),
                                  foregroundColor: _primary,
                                  side: const BorderSide(color: _primary, width: 1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: onLogout,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Sign Out'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                                  foregroundColor: const Color(0xFFE53935),
                                  side: const BorderSide(color: Color(0xFFE53935), width: 1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => _EditProfileDialog(
        profile: profile,
        onSave: (name, idNumber, section) {
          ProfileService().updateProfile(
            name: name,
            idNumber: idNumber,
            section: section,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: _primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}

// ── Reusable Info Card ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Colors.white;
    const textPrimary = Color(0xFF263238);
    const textMuted = Color(0xFF78909C);
    const primary = Color(0xFF00796B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: textMuted, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reusable Stat Card ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Colors.white;
    const textMuted = Color(0xFF78909C);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Edit Profile Dialog ──────────────────────────────────────────────────────

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.onSave});
  final UserProfile profile;
  final void Function(String name, String idNumber, String section) onSave;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _idCtrl;
  late TextEditingController _sectionCtrl;

  static const _primary = Color(0xFF00796B);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _idCtrl = TextEditingController(text: widget.profile.idNumber);
    _sectionCtrl = TextEditingController(text: widget.profile.section);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Colors.white;
    const textPrimary = Color(0xFF263238);
    const textMuted = Color(0xFF78909C);

    final inputDecoration = InputDecoration(
      labelStyle: const TextStyle(color: textMuted),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Profile Info',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _idCtrl,
                style: const TextStyle(color: textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Student ID Number'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _sectionCtrl,
                style: const TextStyle(color: textPrimary),
                decoration: inputDecoration.copyWith(labelText: 'Section'),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      widget.onSave(
                        _nameCtrl.text,
                        _idCtrl.text,
                        _sectionCtrl.text,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Save Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
