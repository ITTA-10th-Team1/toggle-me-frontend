import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const onboarding = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.onboardingTop,
      AppColors.onboardingUpper,
      AppColors.onboardingLower,
      AppColors.onboardingBottom,
    ],
    stops: [0, 0.32, 0.68, 1],
  );
}
