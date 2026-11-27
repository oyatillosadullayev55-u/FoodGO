import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/marketplace.dart';

Color serviceStatusColor(ServiceStatus status) => switch (status) {
  ServiceStatus.fresh => AppColors.warning,
  ServiceStatus.completed => AppColors.success,
  ServiceStatus.rejected || ServiceStatus.cancelled => AppColors.error,
  _ => AppColors.primary,
};
