import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seshlly/core/errors/app_error.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class ErrorView extends StatelessWidget {
  final AppError appError;
  final String buttonText;
  final String image;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.appError,
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
                appError.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width / 4,
                height: 35,
                child: ElevatedButton(
                  onPressed: () {
                    if (appError.statusCode == 401 &&
                        appError.message == 'Token expired') {
                      context.read<AuthBloc>().add(const UserTokeExpire());
                    } else {
                      onRetry();
                    }
                  },
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
