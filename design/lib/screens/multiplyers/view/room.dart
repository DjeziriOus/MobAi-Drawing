import 'package:design/screens/multiplyers/logic/room_cubit.dart';
import 'package:design/screens/multiplyers/logic/room_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomScreen extends StatelessWidget {
  RoomScreen({super.key, required this.isCreator,  this.roomID});

  final bool isCreator;
  String? roomID;

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.red,
      body: BlocProvider(
        create: (context)=>isCreator?RoomCubit(true, '7'):RoomCubit(false, '7',enteredRoomId: roomID),
        child: BlocConsumer<RoomCubit,RoomState>(
          
          builder:(context,state){
            final cubit = BlocProvider.of<RoomCubit>(context);
            return Container(
              color: Colors.amber,
              child:Text(cubit.roomId ?? 'No Room ID'),);
          } , 
          listener: (BuildContext context, RoomState state){
            if(state is EnterRoom){
              print('roooooooom id');
              print(state.roomID);
            } 
            if (state is StartGame){
              print('Start the game');
              print(state.roomID);
            }
          }),
        
        ),
    );
  }
}