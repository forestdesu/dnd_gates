import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {

  static const _profileTextStyle = TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500);

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _handleSignIn() async {
    final auth = context.read<AuthController>();

    debugPrint('=== GOOGLE LOGIN START ===');

    final ok = await auth.signInWithGoogle();

    debugPrint('=== GOOGLE LOGIN RESULT: $ok ===');

    if (!ok && mounted) {
      _showMockLoginDialog();
    }
  }

  Future<void> _showMockLoginDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final photoController = TextEditingController(
      text: 'https://lh3.googleusercontent.com/a/default-user',
    );

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
          title: const Text(
            'Вход (режим разработки)',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Введите ваше имя',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'example@gmail.com',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: photoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'URL фото (опционально)',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  context.read<AuthController>().loginMock(
                    name: nameController.text,
                    email: emailController.text,
                    photoUrl: photoController.text.isNotEmpty
                        ? photoController.text
                        : 'https://lh3.googleusercontent.com/a/default-user',
                  );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Войти'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProfileDialog() async {
    final profile = context.read<AuthController>().userProfile;
    final nameController = TextEditingController(text: profile['name'] ?? '');
    final photoController = TextEditingController(text: profile['photoUrl'] ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(37, 37, 39, 1.0),
          title: const Text('Редактировать профиль', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Имя', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 8),
            TextField(controller: photoController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'URL фото', labelStyle: TextStyle(color: Colors.white70))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Сохранить')),
          ],
        );
      },
    );

    if (ok == true) {
      context.read<AuthController>().updateProfile(
        name: nameController.text,
        photoUrl: photoController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    if (!auth.isAuthenticated) {
      return Stack(children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Войти через Google'),
                onPressed: _handleSignIn,
              ),
            ),
          ),
        )
      ]);
    }

    final userProfile = auth.userProfile;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 48,
                backgroundImage: (auth.userProfile['photoUrl'] != null && auth.userProfile['photoUrl']!.isNotEmpty) ? NetworkImage(auth.userProfile['photoUrl']!) : null,
                child: (auth.userProfile['photoUrl'] == null || auth.userProfile['photoUrl']!.isEmpty) ? const Icon(Icons.person, size: 48) : null,
              ),
              const SizedBox(height: 12),
              Text(auth.userProfile['name'] ?? '', style: _profileTextStyle),
              const SizedBox(height: 6),
              Text(auth.userProfile['email'] ?? '', style: _profileTextStyle),
              const SizedBox(height: 12),
              Text('Дата регистрации: ${_formatDate(auth.userProfile['registeredAt'])}', style: _profileTextStyle),
              const SizedBox(height: 32),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PressableActionButton(
                      icon: Icons.add_a_photo,
                      label: 'Выбрать фото',
                      onTap: () {
                      },
                    ),
                    const SizedBox(width: 20),
                    _PressableActionButton(
                      icon: Icons.edit,
                      label: 'Изменить',
                      onTap: _showEditProfileDialog,
                    ),
                    const SizedBox(width: 20),
                    _PressableActionButton(
                      icon: Icons.settings,
                      label: 'Настройки',
                      onTap: () {
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FractionallySizedBox(
                widthFactor: 0.9,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: auth.signOut,
                  child: const Text('Выйти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressableActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PressableActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PressableActionButton> createState() => _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color.fromARGB(255, 60, 40, 40)
              : const Color.fromARGB(255, 40, 40, 40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _isPressed ? Colors.red : Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



