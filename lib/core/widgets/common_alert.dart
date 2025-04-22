import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gplx/core/services/api/errors/api_exceptions.dart';

class CommonAlert extends StatelessWidget {
  const CommonAlert({super.key, required this.exception, this.onRetry});
  final dynamic exception;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    var errMsg = 'Something went wrong, please try again later!';

    if (exception is ApiException) {
      // Customize error message by type if need
      errMsg = (exception as ApiException).error.message ?? errMsg;
    } else {
      // Maybe push it in crashlytics service like Firbase, Datadog, etc
      if (kDebugMode) {
        errMsg = exception.toString();
      }
      log(exception.toString());
    }

    return AlertDialog.adaptive(
      content: Center(
        child: Text(errMsg),
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          )
      ],
    );
  }
}
