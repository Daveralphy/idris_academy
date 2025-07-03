import 'package:flutter/material.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
      ),
      body: const Center(
        child: Text('Your earned certificates will appear here.'),
      ),
    );
  }
}