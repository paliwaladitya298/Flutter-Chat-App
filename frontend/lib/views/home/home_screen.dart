import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/socket_provider.dart';
import '../../models/chat.dart';
import '../../models/user.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearchingUsers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch initial chat list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchChats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearchingUsers = true;
    });
    final results = await Provider.of<ChatProvider>(context, listen: false).searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearchingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChatApp',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'CHATS'),
            Tab(text: 'FIND FRIENDS'),
            Tab(text: 'PROFILE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatsTab(currentUser.id),
          _buildSearchTab(currentUser.id),
          _buildProfileTab(currentUser),
        ],
      ),
    );
  }

  // Chats listing tab
  Widget _buildChatsTab(String currentUserId) {
    final chatProvider = context.watch<ChatProvider>();
    final socketProvider = context.watch<SocketProvider>();
    
    if (chatProvider.isLoadingChats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No conversations yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Start Chatting'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: chatProvider.fetchChats,
      child: ListView.separated(
        itemCount: chatProvider.chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
        itemBuilder: (context, index) {
          final chat = chatProvider.chats[index];
          final partner = chat.getChatPartner(currentUserId);
          final isOnline = socketProvider.isUserOnline(partner.id, partner.isOnline);
          final unreadCount = chatProvider.unreadCounts[chat.id] ?? 0;
          final lastMsg = chat.lastMessage;

          String lastMsgTime = '';
          if (lastMsg != null) {
            lastMsgTime = DateFormat('hh:mm a').format(lastMsg.createdAt);
          }

          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: partner.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(partner.avatarUrl)
                      : null,
                  child: partner.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              partner.username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Row(
              children: [
                if (lastMsg != null && lastMsg.sender.id == currentUserId) ...[
                  Icon(
                    Icons.done_all,
                    size: 16,
                    color: lastMsg.isRead ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    chatProvider.typingStates[chat.id] == true
                        ? 'typing...'
                        : (lastMsg?.type == 'image' ? '📷 Image' : (lastMsg?.text ?? '')),
                    style: TextStyle(
                      color: chatProvider.typingStates[chat.id] == true
                          ? Colors.green
                          : (unreadCount > 0 ? Theme.of(context).textTheme.titleLarge?.color : Colors.grey),
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lastMsgTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadCount > 0 ? Colors.green : Colors.grey,
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
            onTap: () {
              chatProvider.setActiveChat(chat, currentUserId);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(partner: partner),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Users searching tab
  Widget _buildSearchTab(String currentUserId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search friends by username or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  _searchUsers('');
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearchingUsers
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'Type above to look up friends'
                              : 'No users found matching query',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.avatarUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(user.avatarUrl)
                                    : null,
                                child: user.avatarUrl.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(user.username),
                              subtitle: Text(user.email),
                              trailing: const Icon(Icons.chat_bubble_outline, color: AppConstants.primaryColorLight),
                              onTap: () async {
                                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                                final chat = await chatProvider.startChat(user.id);
                                if (chat != null && mounted) {
                                  chatProvider.setActiveChat(chat, currentUserId);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(partner: user),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Profile management tab
  Widget _buildProfileTab(User currentUser) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 64,
            backgroundImage: currentUser.avatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(currentUser.avatarUrl)
                : null,
            child: currentUser.avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 64)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            currentUser.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            currentUser.email,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          const Divider(),
          // Dark Mode Switcher List Tile
          SwitchListTile(
            title: const Text('Dark Theme'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: widget.isDarkMode,
            activeColor: AppConstants.primaryColorLight,
            onChanged: widget.onToggleTheme,
          ),
          const Divider(),
          const Spacer(),
          // Logout button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final socketProvider = Provider.of<SocketProvider>(context, listen: false);
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);

                socketProvider.disconnectSocket();
                chatProvider.clearState();
                await authProvider.logout();
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
