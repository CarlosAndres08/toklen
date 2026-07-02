import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';

class ReviewForm extends StatefulWidget {
  const ReviewForm({
    required this.onSubmit,
    this.initialRating = 0,
    this.initialComment = '',
    this.isLoading = false,
    super.key,
  });

  final Future<bool> Function(int rating, String? comment) onSubmit;
  final int initialRating;
  final String initialComment;
  final bool isLoading;

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.initialComment);
    _rating = widget.initialRating;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una calificación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    await widget.onSubmit(
      _rating,
      _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Califica este servicio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return IconButton(
                onPressed: widget.isLoading ? null : () {
                  setState(() => _rating = starIndex);
                },
                icon: Icon(
                  starIndex <= _rating ? Icons.star : Icons.star_border,
                  size: 36,
                  color: AppColors.warning,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _commentController,
            label: 'Comentario (opcional)',
            hintText: 'Cuenta tu experiencia...',
            prefixIcon: Icons.rate_review_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Enviar Reseña',
            icon: Icons.send,
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
