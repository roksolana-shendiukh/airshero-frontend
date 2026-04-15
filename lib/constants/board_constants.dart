import 'package:flutter/material.dart';

const activeStatuses = {
  'Waiting', 'Boarding', 'Baggage Loading', 'Departed', 'Arrived'
};

const statusColors = {
  'Scheduled':       Color(0xFF9E9E9E),
  'Waiting':         Color(0xFF9E9E9E),
  'Boarding':        Color(0xFF2196F3),
  'Baggage Loading': Color(0xFF9C27B0),
  'Departed':        Color(0xFFFF9800),
  'Arrived':         Color(0xFF00BCD4),
  'Completed':       Color(0xFF4CAF50),
  'Cancelled':       Color(0xFFF44336),
};

const colDefs = <({String key, String label, double width})>[
  (key: 'time',     label: 'TIME',     width: 80.0),
  (key: 'flight',   label: 'FLIGHT',   width: 100.0),
  (key: 'route',    label: 'ROUTE',    width: 130.0),
  (key: 'airline',  label: 'AIRLINE',  width: 150.0),
  (key: 'aircraft', label: 'AIRCRAFT', width: 150.0),
  (key: 'status',   label: 'STATUS',   width: 140.0),
];

const itemsPerPage = 15;