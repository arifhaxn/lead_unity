import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // 🟢 Load the saved image path from storage when the drawer opens
  Future<void> _loadProfileImage() async {
    String? imagePath = await _storage.read(key: 'profile_image_path');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  // 🟢 Open the gallery and save the selected image path
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Save the path so it remembers the picture next time you open the app
      await _storage.write(key: 'profile_image_path', value: pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // Safely extract user details
    final name = user?.name ?? 'Unknown User';
    final email = user?.email ?? 'No email provided';
    final studentId = user?.studentId ?? 'N/A';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // --- 1. Top User Info Section ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Profile Picture Area
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      // If we have an image, show it. Otherwise, stay blank so the text shows.
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? Text(
                              firstLetter,
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            )
                          : null, // Hide the text if there is an image
                    ),
                    InkWell(
                      onTap: _pickImage, // 🟢 Triggers the gallery popup
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // User Details
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                if (user?.role == 'student') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "ID: $studentId",
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),

          // --- 2. Middle Actions Section ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                // Theme Toggle
                SwitchListTile(
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w500)),
                  value: themeProvider.isDarkMode,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
                
                const Divider(),

                // Logout Button
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(context);
                    
                    // Optional: Clear the profile picture when logging out
                    // await _storage.delete(key: 'profile_image_path');
                    
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),

          // --- 3. Bottom Info Section ---
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: theme.colorScheme.onSurfaceVariant),
            title: Text("About App", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen()));
            },
          ),
          const SizedBox(height: 20), 
        ],
      ),
    );
  }
}