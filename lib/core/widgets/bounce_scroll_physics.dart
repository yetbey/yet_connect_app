// core/widgets/bounce_scroll_physics.dart (yeni dosya)

import 'package:flutter/material.dart';

class BounceScrollPhysics extends ScrollPhysics {
  final double frictionFactor;

  const BounceScrollPhysics({super.parent, this.frictionFactor = 0.015});

  @override
  BounceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return BounceScrollPhysics(
      parent: buildParent(ancestor),
      frictionFactor: frictionFactor,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset.abs() < 100) {
      return offset;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final simulation = super.createBallisticSimulation(position, velocity);
    if (simulation == null) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      position.pixels + velocity * frictionFactor,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.5, stiffness: 100, damping: 15);
}
