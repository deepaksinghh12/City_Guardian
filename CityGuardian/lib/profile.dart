import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart';
import 'main.dart'; // ✅ For signOutCompletely

class StylishProfilePage extends StatefulWidget {
  const StylishProfilePage({super.key});

  @override
  State<StylishProfilePage> createState() => _StylishProfilePageState();
}

class _StylishProfilePageState extends State<StylishProfilePage> {
  String _name = 'Loading...';
  String _email = 'Loading...';
  int _rewards = 469;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      setState(() {
        _name = _currentUser!.displayName ?? 'No Name';
        _email = _currentUser!.email ?? 'No Email';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E2D3D), Color(0xFF263849)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.grey[400],
                          backgroundImage: _currentUser?.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null,
                          child: _currentUser?.photoURL == null
                              ? const Icon(Icons.person, size: 42, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              buildInteractiveTile(
                context,
                icon: Icons.edit,
                title: 'Edit Your Profile',
                onTap: () async {
                  final updatedProfile = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        initialName: _name,
                        initialEmail: _email,
                        initialPhotoUrl: _currentUser?.photoURL,
                      ),
                    ),
                  );

                  if (updatedProfile != null) {
                    setState(() {
                      _name = updatedProfile['name'] ?? _name;
                      _email = updatedProfile['email'] ?? _email;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rewards',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2D3D),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '$_rewards',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              buildInteractiveTile(
                context,
                icon: Icons.logout,
                title: 'Log out',
                isDanger: true,
                onTap: () {
                  LoginPage.signOutCompletely(context);
                },
              ),

              const SizedBox(height: 30),
            ]),
          ),
        ],
      ),
    );
  }

  Widget buildInteractiveTile(
      BuildContext context, {
        required String title,
        required IconData icon,
        bool isDanger = false,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: isDanger ? Colors.redAccent : Colors.blueGrey[800]),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDanger ? Colors.redAccent : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
