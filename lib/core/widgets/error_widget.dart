import 'package:flutter/material.dart';
import 'package:seshlly/core/errors/app_error.dart';

import '../errors/failure.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final AppError apiFailure;
  final String buttonText;
  final String image;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.apiFailure,
    required this.message,
    required this.onRetry,
    this.buttonText = "Retry",
    this.image = "assets/images/error.png",
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image.asset(image, height: 180),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
