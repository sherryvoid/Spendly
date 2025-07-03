import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Demo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [
          NotificationButton(), // Placed in AppBar for proper context
        ],
      ),
      body: const Center(child: Text('Home Screen')),
    );
  }
}

// Notification Button
class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications, color: Colors.white),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const NotificationPopup(),
        );
      },
    );
  }
}

// Request Model
class FriendRequest {
  final String name;
  FriendRequest({required this.name});
}

class SplitRequest {
  final String name;
  final String place;
  final int amount;
  final int split;
  SplitRequest({
    required this.name,
    required this.amount,
    required this.split,
    required this.place,
  });
}

// Notification Popup
class NotificationPopup extends StatefulWidget {
  const NotificationPopup({super.key});

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<FriendRequest> friendRequests = [
    FriendRequest(name: 'Kanwar'),
    FriendRequest(name: 'Ammar'),
    FriendRequest(name: 'Ali'),
  ];

  List<SplitRequest> splitRequests = [
    SplitRequest(name: 'Sarah', amount: 150, split: 50, place: 'Home'),
    SplitRequest(name: 'John', amount: 40, split: 20, place: 'Restaurant'),
    SplitRequest(name: 'Marie', amount: 100, split: 10, place: 'Cafe'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _acceptFriendRequest(int index) {
    setState(() {
      friendRequests.removeAt(index);
    });
  }

  void _rejectFriendRequest(int index) {
    setState(() {
      friendRequests.removeAt(index);
    });
  }

  void _acceptSplitRequest(int index) {
    setState(() {
      splitRequests.removeAt(index);
    });
  }

  void _rejectSplitRequest(int index) {
    setState(() {
      splitRequests.removeAt(index);
    });
  }

  Widget _buildFriendsRequestList(
    List<FriendRequest> list,
    Function(int) onAccept,
    Function(int) onReject,
  ) {
    if (list.isEmpty) {
      return const Text('No requests.');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${request.name} sent you a request.'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onReject(index),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => onAccept(index),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF358781),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitRequestList(
    List<SplitRequest> list,
    Function(int) onAccept,
    Function(int) onReject,
  ) {
    if (list.isEmpty) {
      return const Text('No requests.');
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.name} sent you a request for splitting ${request.amount} for ${request.place}. Your share: ${request.split}.',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onReject(index),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => onAccept(index),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF358781),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notifications'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [Tab(text: 'Requests'), Tab(text: 'Splits')],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsRequestList(
                    friendRequests,
                    _acceptFriendRequest,
                    _rejectFriendRequest,
                  ),
                  _buildSplitRequestList(
                    splitRequests,
                    _acceptSplitRequest,
                    _rejectSplitRequest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
