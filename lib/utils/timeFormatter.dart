import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String formatTimestamp(Timestamp timestamp) {
  final dateTime = timestamp.toDate(); // Convert to DateTime
  final formatter = DateFormat(
    'MMM d, yyyy – h:mm a',
  ); // Example: Jun 23, 2025 – 4:45 PM
  return formatter.format(dateTime);
}
