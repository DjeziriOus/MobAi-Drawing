import 'package:design/screens/multiplyers/logic/room_cubit.dart';
import 'package:design/screens/multiplyers/logic/room_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.red,
      body: BlocProvider(
        create: (context)=>RoomCubit(true, '2'),
        child: BlocConsumer<RoomCubit,RoomState>(
          
          builder:(context,state){
            final cubit = BlocProvider.of<RoomCubit>(context);
            return Container(color: Colors.amber,);
          } , 
          listener: (BuildContext context, RoomState state){
            
          }),
        
        ),
    );
  }
}