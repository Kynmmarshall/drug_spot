import 'package:flutter/material.dart';

enum UserType { pharmacy, patient }

extension UserTypeX on UserType {
  IconData get icon =>
      this == UserType.pharmacy ? Icons.local_pharmacy : Icons.person_outline;
}
