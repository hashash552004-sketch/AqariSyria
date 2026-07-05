import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String propertyId;
  final String reportedBy;
  final String reason;
  final String? description;
  final DateTime createdAt;
  final String status;

  Report({
    this.id = '',
    this.propertyId = '',
    this.reportedBy = '',
    this.reason = '',
    this.description,
    DateTime? createdAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  factory Report.fromFirestore(Map<String, dynamic> data, String id) {
    return Report(
      id: id,
      propertyId: data['propertyId']?.toString() ?? '',
      reportedBy: data['reportedBy']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      description: data['description']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'reportedBy': reportedBy,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
