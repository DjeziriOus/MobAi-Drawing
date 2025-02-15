import 'package:design/screens/multiplyers/logic/room_cubit.dart';
import 'package:design/screens/multiplyers/logic/room_state.dart';
import 'package:design/screens/multiplyers/view/drawer_screen.dart';
import 'package:design/screens/multiplyers/view/gusts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomScreen extends StatelessWidget {
  RoomScreen({super.key, required this.isCreator, this.roomID});

  final bool isCreator;
  String? roomID;
  late RoomCubit cc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: BlocProvider(
        create: (context) => isCreator
            ? RoomCubit(true, '1')
            : RoomCubit(false, '2', enteredRoomId: roomID),
        child: BlocConsumer<RoomCubit, RoomState>(builder: (context, state) {
          final cubit = BlocProvider.of<RoomCubit>(context);
          cc = cubit;

          return Container(
            padding: const EdgeInsets.all(16.0),
            margin:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 4),
                  blurRadius: 8.0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                cubit.roomId ?? 'No Room ID',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }, listener: (BuildContext context, RoomState state) {
          if (state is EnterRoom) {
            print('roooooooom id');
            print(state.roomID);
          }
          if (state is StartGame) {
            print('Start the game');
            print(state.roomID);
            bool _isDrawer = state.isDrawer;
            if (_isDrawer) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DrawerScreen(
                            socket: state.streamSocket,
                            channel: state.channel,
                            uid: state.uid,
                          )));
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GustsScreen(
                            channel: cc.channel,
                            streamSocket: cc.streamSocket,
                            uid: cc.uid,
                          )));
            }
          }
        }),
      ),
    );
  }
}
