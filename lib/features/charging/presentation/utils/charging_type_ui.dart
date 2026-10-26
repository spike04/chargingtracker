import 'package:flutter/material.dart';

import '../../domain/entities/charging_session.dart';

extension ChargingTypeUi on ChargingType {
  IconData get icon => switch (this) {
    ChargingType.fast => Icons.bolt_rounded,
    ChargingType.slow => Icons.battery_charging_full_rounded,
  };

  Color color(ColorScheme scheme) => switch (this) {
    ChargingType.fast => scheme.primary,
    ChargingType.slow => const Color(0xFFF59E0B),
  };
}
