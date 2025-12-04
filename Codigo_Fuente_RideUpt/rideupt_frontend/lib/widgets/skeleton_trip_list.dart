import 'package:flutter/material.dart';
import 'package:rideupt_app/widgets/lottie_loading.dart';

class SkeletonTripList extends StatelessWidget {
  const SkeletonTripList({super.key});

  @override
  Widget build(BuildContext context) {
    return LottieLoading(
      message: 'Cargando viajes...',
    );
  }
}

