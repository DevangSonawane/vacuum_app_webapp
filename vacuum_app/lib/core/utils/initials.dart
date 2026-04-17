import 'package:characters/characters.dart';

String initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.take(2).toString();
  final first = parts.first.characters.take(1).toString();
  final last = parts.last.characters.take(1).toString();
  return (first + last).toUpperCase();
}
