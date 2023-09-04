import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nacexvlymhbpssbkacli.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hY2V4dmx5bWhicHNzYmthY2xpIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTM1NTMwODUsImV4cCI6MjAwOTEyOTA4NX0.ghaYDfoCxChwZCd7SYju_vtk9z-sMlob_OiDCWfMu_4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Login',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

final supabase = Supabase.instance.client;

  /// Function to generate a random 16 character string.
String _generateRandomString() {
  final random = Random.secure();
  return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
}

Future<AuthResponse> signInWithGoogle() async {
  // Just a random string
  final rawNonce = _generateRandomString();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

  final clientId = Platform.isAndroid ? 
  '500451147067-na1ffashrh8sevsv7k1rtj44s16i7toi.apps.googleusercontent.com' : 
  '500451147067-46dejak1vlq0qev45gsocd9i5lonojcg.apps.googleusercontent.com';

  /// reverse DNS form of the client ID + `:/` is set as the redirect URL
  final redirectUrl = '${clientId.split('.').reversed.join('.')}:/';
  //final redirectUrl = 'com.idhpaul.supabase_auth_iap:/';

  /// Fixed value for google login
  const discoveryUrl =
      'https://accounts.google.com/.well-known/openid-configuration';

  const appAuth = FlutterAppAuth();


  final result = await appAuth.authorize(
    AuthorizationRequest(
      clientId,
      redirectUrl,
      discoveryUrl: discoveryUrl,
      nonce: hashedNonce,
      scopes: [
        'openid',
        'email',
      ],
    ),
  );


  if (result == null) {
    throw 'No result';
  }

  // Request the access and id token to google
  final tokenResult = await appAuth.token(
    TokenRequest(
      clientId,
      redirectUrl,
      authorizationCode: result.authorizationCode,
      discoveryUrl: discoveryUrl,
      codeVerifier: result.codeVerifier,
      nonce: result.nonce,
      scopes: [
        'openid',
        'email',
      ],
    ),
  );

  final idToken = tokenResult?.idToken;

  if (idToken == null) {
    throw 'No idToken';
  }

  return supabase.auth.signInWithIdToken(
    provider: Provider.google,
    idToken: idToken,
    nonce: rawNonce,
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: signInWithGoogle, 
          icon: const SizedBox(
            height: 36,
            width: 36,
            child: Icon(
              Icons.favorite,
              color: Colors.pink,
              size: 24.0,
              semanticLabel: 'Text to announce in accessibility modes',
            )),
          label: const Text('Sign in with Google')
        )
      ),
    );
  }
}