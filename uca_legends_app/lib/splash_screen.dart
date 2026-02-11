import 'package:flutter/material.dart';
import 'api_service.dart';
import 'main.dart'; // Para acceder a LoginScreen y MainScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    // Ejecutamos la comprobación tras el primer renderizado para evitar bloqueos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    // 1. Un pequeño delay estético para ver el logo (opcional)
    await Future.delayed(const Duration(seconds: 1));

    // 2. Verificamos contra el Backend
    bool isValid = await ApiService.verifyToken();

    if (!mounted) return; // Seguridad por si el widget se desmontó

    if (isValid) {
      // TOKEN VALIDO -> HOME
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen())
      );
    } else {
      // TOKEN INVALIDO O EXPIRADO -> BORRAR Y LOGIN
      await ApiService.logout(); // Esto borra el secure storage

      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C), // Fondo oscuro
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Icon(Icons.shield, size: 100, color: Color(0xFFD32F2F)),
            const SizedBox(height: 20),
            const Text(
              "LEGENDS APP",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0
              ),
            ),
            const SizedBox(height: 40),
            // Spinner visible para saber que está cargando
            const CircularProgressIndicator(color: Color(0xFFC9AA71)),
          ],
        ),
      ),
    );
  }
}