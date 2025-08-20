import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/mood_entry.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  const PatientDetailScreen({super.key, required this.patientId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: Text(patientName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: svc.userDoc(patientId),
              builder: (context, snap) {
                final data = snap.data?.data();
                final emergency = (data?['emergencyContact'] ?? {}) as Map<String, dynamic>;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency contact', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Name: ${emergency['name'] ?? '—'}'),
                        Text('Phone: ${emergency['phone'] ?? '—'}'),
                        Text('Relationship: ${emergency['relationship'] ?? '—'}'),
                      ],
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
            Text('Mood history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: svc.moodsForPatient(patientId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ));
                final items = snap.data!.docs.map((d) => MoodEntry.fromMap(d.id, d.data())).toList();
                if (items.isEmpty) return const Text('No mood entries yet.');
                return Column(
                  children: items.map((m) => ListTile(
                    leading: const Icon(Icons.emoji_emotions),
                    title: Text(m.mood),
                    subtitle: Text(m.note ?? ''),
                    trailing: Text(m.timestamp?.toLocal().toString().substring(0, 16) ?? ''),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
