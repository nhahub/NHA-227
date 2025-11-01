import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/blocs/auth/auth_bloc.dart';
import 'package:medilink_app/blocs/auth/auth_event.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
              context.go('/signin');
            },
          ),
        ],
      ),
      body: Center(child: Text('Welcome to Medilink!')),
    );
  }
}