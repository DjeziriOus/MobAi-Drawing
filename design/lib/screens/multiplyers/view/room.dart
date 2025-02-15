import 'package:design/screens/multiplyers/logic/room_cubit.dart';
import 'package:design/screens/multiplyers/logic/room_state.dart';
import 'package:design/screens/multiplyers/view/drawer_screen.dart';
import 'package:design/screens/multiplyers/view/gusts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomScreen extends StatelessWidget {
  RoomScreen({
    super.key, 
    required this.isCreator, 
    this.roomID,
  });

  final bool isCreator;
  final String? roomID;
  late RoomCubit cc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => isCreator 
          ? RoomCubit(true, '107')
          : RoomCubit(false, '107', enteredRoomId: roomID),
        child: BlocConsumer<RoomCubit, RoomState>(
          listener: _handleStateChanges,
          builder: (context, state) {
            final cubit = BlocProvider.of<RoomCubit>(context);
            cc = cubit;
            return _buildRoomUI(context, cubit);
          },
        ),
      ),
    );
  }

  Widget _buildRoomUI(BuildContext context, RoomCubit cubit) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade900,
            Colors.purple.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, cubit),
            Expanded(
              child: _buildRoomContent(context, cubit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RoomCubit cubit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                isCreator ? 'Room Host' : 'Room Guest',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  // Add settings functionality
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRoomIdCard(context, cubit),
        ],
      ),
    );
  }

  Widget _buildRoomIdCard(BuildContext context, RoomCubit cubit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.meeting_room,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Text(
            'Room ID: ${cubit.roomId ?? 'Loading...'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white70),
            onPressed: () {
              // Add copy functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Room ID copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoomContent(BuildContext context, RoomCubit cubit) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPlayersList(),
          const Spacer(),
          if (isCreator) _buildHostControls(context),
          _buildGameStatus(),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Players',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlayerItem('Player 1', isHost: true),
          _buildPlayerItem('Player 2'),
          _buildPlayerItem('Player 3'),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(String name, {bool isHost = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (isHost) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Host',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHostControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Add start game functionality
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow),
            SizedBox(width: 8),
            Text(
              'Start Game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white70,
          ),
          SizedBox(width: 8),
          Text(
            'Waiting for host to start the game...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _handleStateChanges(BuildContext context, RoomState state) {
    if (state is EnterRoom) {
      print('Room ID: ${state.roomID}');
    } else if (state is StartGame) {
      print('Starting game...');
      if (state.isDrawer) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrawerScreen(
              socket: state.streamSocket,
              channel: state.channel,
              uid: state.uid,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GustsScreen(
              channel: cc.channel,
              streamSocket: cc.streamSocket,
              uid: cc.uid,
            ),
          ),
        );
      }
    }
  }
}