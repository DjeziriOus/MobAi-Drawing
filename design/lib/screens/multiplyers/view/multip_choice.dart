import 'package:design/screens/multiplyers/view/room.dart';
import 'package:design/widgets/mode_button.dart';
import 'package:design/widgets/splash_header.dart';
import 'package:flutter/material.dart';

class MultipChoice extends StatelessWidget {
  const MultipChoice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900, Colors.purple.shade800],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    ModeButton(
                      icon: Icons.create,
                      label: 'Create room',
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RoomScreen(
                                      isCreator: true,
                                    )));
                      },
                    ),
                    const SizedBox(height: 50),
                    const SizedBox(height: 20),
                    ModeButton(
                      icon: Icons.groups,
                      label: 'Enter Room',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            TextEditingController roomNameController =
                                TextEditingController();
                            return AlertDialog(
                              title: Text('Enter Room Name'),
                              content: TextField(
                                controller: roomNameController,
                                decoration:
                                    InputDecoration(hintText: "Room number"),
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Enter'),
                                  onPressed: () {
                                    String roomName = roomNameController.text;
                                    // Handle the room name here
                                    Navigator.of(context).pop();
                                     Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  RoomScreen(
                                      isCreator: false,
                                      roomID: roomName,
                                    )));

                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
