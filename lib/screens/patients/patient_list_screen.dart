import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/avatar_tile.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final svc = FirestoreService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.myChats(auth.user!.uid),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No assigned patients yet.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final chat = docs[i];
            final patientId = chat['patientId'] as String? ?? '';
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: svc.userDoc(patientId),
              builder: (context, userSnap) {
                final data = userSnap.data?.data() ?? {};
                final name = data['displayName'] ?? 'Patient';
                return AvatarTile(
                  title: name,
                  subtitle: 'Tap to view details',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PatientDetailScreen(
                      patientId: patientId,
                      patientName: name,
                    )));
                  },
                );
              }
            );
          },
        );
      },
    );
  }
}
