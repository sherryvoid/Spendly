import 'package:flutter/material.dart';

List<Map<String, dynamic>> transactionsData = [
  {
    'icon': const Icon(Icons.attach_money_rounded, color: Colors.white),
    'color': Colors.yellow[700],
    'name': 'Food',
    'totalAmount': '-\$40,00',
    'date': 'Today',
  },
  {
    'icon': const Icon(Icons.attach_money_rounded, color: Colors.white),
    'name': 'TK',
    'color': Colors.purple[700],
    'totalAmount': '-\$10,00',
    'date': 'Yesterday',
  },
  {
    'icon': const Icon(Icons.attach_money_rounded, color: Colors.white),
    'name': 'Rewe',
    'color': Colors.red[700],
    'totalAmount': '-\$90,00',
    'date': 'Yesterday',
  },
  {
    'icon': const Icon(Icons.attach_money_rounded, color: Colors.white),
    'name': 'Aldi',
    'color': Colors.blue[700],
    'totalAmount': '-\$10,00',
    'date': 'Yesterday',
  },
];
