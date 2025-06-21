import 'package:flutter/material.dart';
import 'package:my_chat_app/login.dart';
import 'package:my_chat_app/screeen/quotes_screen.dart';
import 'chatpage.dart';
import 'constants.dart';
import 'model.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  Future<List<Profile>> _usersFuture = Future.value([]);
  String? myUserId;
  String myUsername = "User"; // Default username
  TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() async {
    myUserId = supabase.auth.currentUser?.id;
    if (myUserId != null) {
      setState(() {
        _usersFuture = _fetchUsers(); // Assign the real fetch operation
      });
      await _fetchCurrentUser();
      setState(() {});
    }else{
      // Redirect to login page if user is not logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('id', myUserId!)
          .maybeSingle();

      if (response != null) {
        setState(() {
          myUsername = response['username'] ?? 'User';
          _usernameController.text = myUsername;
        });
      } else {
        // Profile doesn’t exist, create one
        final defaultUsername = 'User_${myUserId!.substring(0, 8)}';
        await supabase.from('profiles').insert({
          'id': myUserId!,
          'username': defaultUsername,
        });
        setState(() {
          myUsername = defaultUsername;
          _usernameController.text = defaultUsername;
        });
      }
    } catch (e) {
      print('Error fetching/creating profile: $e');
      _showSnackbar('Failed to load profile: $e', Colors.red, icon: Icons.error);
    }
  }
  Future<void> _updateUsername() async {
    String newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      _showSnackbar("Username cannot be empty!", Colors.red, icon: Icons.error);
      _usernameController.text = myUsername;
      if (context.mounted) Navigator.pop(context);
      return;
    }
    if (newUsername == myUsername) {
      _showSnackbar("This is already your username!", Colors.orange, icon: Icons.warning);
      _usernameController.text = myUsername;
      if (context.mounted) Navigator.pop(context);
      return;
    }

    // ✅ Check if the username already exists
    final existingUser = await supabase
        .from('profiles')
        .select('id')
        .eq('username', newUsername)
        .maybeSingle();

    if (existingUser != null) {
      _showSnackbar("Username already taken! Please choose another.", Colors.red, icon: Icons.error);
      _usernameController.text = myUsername;
      if (context.mounted) Navigator.pop(context);
      return;
    }

    // ✅ Update username in database
    await supabase.from('profiles').update({'username': newUsername}).eq('id', myUserId!);

    if (context.mounted) {
      setState(() {
        myUsername = newUsername; // ✅ Update UI safely
        _usernameController.text = newUsername;
      });
      Navigator.pop(context);
      _showSnackbar("Username updated successfully!", Colors.green, icon: Icons.check_circle);
    }
  }

// ✅ Helper function to show messages
  void _showSnackbar(String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 22), // ✅ Optional icon
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  Future<List<Profile>> _fetchUsers() async {
    if (myUserId == null) return [];

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .neq('id', myUserId!);
      return (response as List<dynamic>).map((data) => Profile.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching users: $e');
      rethrow; // Propagate to FutureBuilder
    }
  }
  void _startChat(Profile user) async {
    if (myUserId == null) {
      _showSnackbar("Error: User not logged in", Colors.red, icon: Icons.error);
      return;
    }

    try {
      final userId = user.id;
      final sortedPair = myUserId!.compareTo(userId) < 0
          ? '$myUserId-$userId'
          : '$userId-$myUserId';

      final existingConversation = await supabase
          .from('conversations')
          .select('id')
          .eq('sorted_pair', sortedPair)
          .maybeSingle();

      String conversationId;

      if (existingConversation == null) {
        final newConversation = await supabase.from('conversations').insert({
          'user1_id': myUserId,
          'user2_id': userId,
          'sorted_pair': sortedPair, // Include sorted_pair
        }).select().single();

        conversationId = newConversation['id'];
      } else {
        conversationId = existingConversation['id'];
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: conversationId,
            otherUser: user,
          ),
        ),
      );
    } catch (error) {
      print("Error starting chat: $error");
      _showSnackbar("Failed to start chat: $error", Colors.red, icon: Icons.error);
    }
  }
  void _logout() async {
    await supabase.auth.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false, // Clears all previous routes
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=> QuotesScreen()));
          }, icon: Icon(Icons.format_quote_sharp)),
        )],
      ),
      drawer: _buildDrawer(context),
      body: FutureBuilder<List<Profile>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString().contains('42P01')
                ? 'Database table missing. Contact support.'
                : 'Error loading users: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text("No users found.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)));
          }

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ),
                  title: Text(user.username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Text("Tap to chat", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  trailing: Icon(Icons.message, color: Colors.blueAccent, size: 22),
                  onTap: () => _startChat(user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.60, // Adjusted width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header with User Info
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 16, right: 16),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      myUsername[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    myUsername,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text(
                    "badboy@gmail.com",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Username Change Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blueAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: "Update username",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: _updateUsername,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Menu Items
            _buildDrawerItem(Icons.settings, "Settings", () {}),
            _buildDrawerItem(Icons.help_outline, "Help & Support", () {}),
            const Spacer(), // Pushes logout button to the bottom

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 3,
                ),
                icon: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: const Icon(Icons.logout),
                ),
                label: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: const Text("Logout"),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper Method for Drawer Items
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.transparent,
      hoverColor: Colors.blue,
    );
  }

}
