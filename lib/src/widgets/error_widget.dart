import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Error display widget
class ErrorDisplayWidget extends StatelessWidget {
  final ErrorHandlingType type;
  final Widget? customWidget;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const ErrorDisplayWidget({
    Key? key,
    required this.type,
    this.customWidget,
    this.onRetry,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ErrorHandlingType.iconWithRetry:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Failed to load image',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        );

      case ErrorHandlingType.customWidget:
        return customWidget ?? _defaultErrorWidget(context);

      case ErrorHandlingType.callbackOnly:
      // Don't show any UI, just trigger callback
        return const SizedBox.shrink();
    }
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image,
        size: 64,
        color: Colors.grey.shade400,
      ),
    );
  }
}