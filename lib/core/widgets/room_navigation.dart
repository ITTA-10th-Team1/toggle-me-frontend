import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';

/// Direct browser links have no route to pop after a reload/new tab.
void popOrGoRoom(BuildContext context, [Object? result]) {
  if (context.canPop()) {
    context.pop(result);
  } else {
    context.go(AppRoutes.room);
  }
}
