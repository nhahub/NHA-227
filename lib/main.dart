import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import 'repositories/product_repository.dart';
import 'router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository = AuthRepository();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide app-wide repositories and blocs here so screens can access them
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductRepository()),
        // Make AuthRepository available to widgets so they can call ensureSignedIn/openSignInScreen
        Provider<AuthRepository>.value(value: authRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          title: 'Medilink',
          theme: ThemeData(primarySwatch: Colors.blue),
        ),
      ),
    );
  }
}