import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../auth_provider.dart';
import '../home_page.dart';
import '../theme/theme_provider.dart';
import 'about_app_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _storage = const FlutterSecureStorage();
  File? _profileImage;
  String _savedIdentifier = 'SUP'; // 🟢 Added to store fetched abbreviation

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // 🟢 Now loads both image and abbreviation
  }

  Future<void> _loadInitialData() async {
    String? imagePath = await _storage.read(key: 'profile_image_path');
    String? ident = await _storage.read(key: 'login_identifier');

    if (mounted) {
      setState(() {
        if (imagePath != null && File(imagePath).existsSync()) {
          _profileImage = File(imagePath);
        }
        if (ident != null && ident.isNotEmpty) {
          _savedIdentifier = ident.toUpperCase(); // E.g., sets "EBH"
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final permanentPath = '${directory.path}/profile_picture.png';
        final savedImage = await File(pickedFile.path).copy(permanentPath);

        setState(() {
          _profileImage = savedImage;
        });
        await _storage.write(key: 'profile_image_path', value: permanentPath);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final name = user?.name ?? 'Unknown User';
    final email = user?.email?.trim() ?? '';
    final studentId = user?.studentId ?? 'N/A';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // 🟢 Magic Check: Detect if the logged-in user is Ebrahim Sir
    final bool isEbrahimSir = name.contains('Ebrahim Hossain') ||
        name.contains('Ebrahim Hussain') ||
        name.contains('MD Ebrahim Hossain') ||
        name.contains('MD. Ebrahim Hossain') ||
        name.contains('Md. Ebrahim Hossain') ||
        email == 'EBH' ||
        name.toUpperCase() == 'EBH';

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- 1. Top User Info Section ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                  bottom: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                                width: 3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: theme.colorScheme.surface,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!) as ImageProvider
                                : (isEbrahimSir
                                    ? const AssetImage(
                                        "assets/template/crew/sir.jpeg")
                                    : null),
                            child: _profileImage == null && !isEbrahimSir
                                ? Text(
                                    firstLetter,
                                    style: TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary),
                                  )
                                : null,
                          ),
                        ),
                        InkWell(
                          onTap: _pickImage,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    // 🟢 Conditional Role Badges
                    if (user?.role == 'student')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_rounded,
                                size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              studentId,
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else if (user?.role == 'supervisor')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              _savedIdentifier,
                              style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty && email.length > 4) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (user?.role == 'supervisor') ...[
                  const SizedBox(height: 4),
                  Text(
                    user?.designation ?? 'Supervisor',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // --- 2. Middle Actions Section ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: themeProvider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: "Dark Mode",
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (value) => themeProvider.setDarkMode(value),
                  ),
                  onTap: () => themeProvider.toggleTheme(),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AboutAppScreen()));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // 🟢 Brought back the white box for the logo!
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 13, 8, 49),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("About App",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              SizedBox(height: 4),
                              Text("LeadUnity • v1.0.0",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 3. Bottom Logout Section ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDrawerItem(
              context: context,
              icon: Icons.logout_rounded,
              title: "Logout",
              isDestructive: true,
              onTap: () async {
                Navigator.pop(context);
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color =
        isDestructive ? Colors.redAccent : theme.colorScheme.onSurface;
    final bgColor =
        isDestructive ? Colors.redAccent.withOpacity(0.1) : Colors.transparent;

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: trailing,
    );
  }
}
