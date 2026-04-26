import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.event,
    required this.title,
    required this.message,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    required this.read,
    required this.fromDb,
    required this.serverId,
  });

  final String id; // unique local id (string)
  final int? serverId; // nullable for WS-only items
  final String event;
  final String title;
  final String message;
  final String? entityType; // job | report | amc | ...
  final String? entityId;
  final DateTime timestamp;
  final bool read;
  final bool fromDb;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      serverId: serverId,
      event: event,
      title: title,
      message: message,
      entityType: entityType,
      entityId: entityId,
      timestamp: timestamp,
      read: read ?? this.read,
      fromDb: fromDb,
    );
  }
}

({String title, Color color, IconData icon}) notificationMeta(String event) {
  switch (event) {
    case 'job_raised':
      return (
        title: 'New Job Raised',
        color: AppColors.blue600,
        icon: Icons.work_outline,
      );
    case 'job_status':
      return (
        title: 'Job Status Updated',
        color: AppColors.amber500,
        icon: Icons.sync_alt,
      );
    case 'report_submitted':
      return (
        title: 'Report Submitted',
        color: AppColors.gray500,
        icon: Icons.description_outlined,
      );
    case 'report_reviewed':
      return (
        title: 'Report Reviewed',
        color: AppColors.emerald500,
        icon: Icons.verified_outlined,
      );
    case 'amc_expiring':
      return (
        title: 'AMC Renewal Reminder',
        color: AppColors.orange500,
        icon: Icons.schedule_outlined,
      );
    case 'amc_created':
      return (
        title: 'New AMC Contract',
        color: AppColors.blue600,
        icon: Icons.verified_user_outlined,
      );
    default:
      return (
        title: 'Notification',
        color: AppColors.blue600,
        icon: Icons.notifications_none,
      );
  }
}

String formatNotificationMessage(String event, Map<String, dynamic> data) {
  String s(Object? v) => v == null ? '' : v.toString();
  switch (event) {
    case 'job_raised':
      return '${s(data['entity_id']).isEmpty ? 'A new job' : s(data['entity_id'])} was raised';
    case 'job_status':
      final id = s(data['entity_id']).isEmpty ? 'Job' : s(data['entity_id']);
      final status = s(data['status']).isEmpty
          ? 'new status'
          : s(data['status']);
      return '$id moved to "$status"';
    case 'report_submitted':
      return '${s(data['entity_id']).isEmpty ? 'A report' : s(data['entity_id'])} submitted for review';
    case 'report_reviewed':
      final id = s(data['entity_id']).isEmpty ? 'Report' : s(data['entity_id']);
      final status = s(data['status']).isEmpty
          ? 'reviewed'
          : s(data['status']).toLowerCase();
      return '$id was $status';
    case 'amc_expiring':
      return '${s(data['entity_id']).isEmpty ? 'An AMC' : s(data['entity_id'])} is expiring soon';
    case 'amc_created':
      return '${s(data['entity_id']).isEmpty ? 'A new AMC' : s(data['entity_id'])} contract was created';
    default:
      final msg = s(data['message']);
      return msg.isEmpty ? 'New notification' : msg;
  }
}
