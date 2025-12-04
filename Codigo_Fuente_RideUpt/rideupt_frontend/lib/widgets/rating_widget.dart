// lib/widgets/rating_widget.dart
import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color color;
  final bool showNumber;
  final bool showCount;

  const RatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.color = Colors.amber,
    this.showNumber = false,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNumber) ...[
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
        ],
        ...List.generate(maxRating, (index) {
          return Icon(
            index < rating.floor() 
              ? Icons.star 
              : index < rating 
                ? Icons.star_half 
                : Icons.star_border,
            color: color,
            size: size,
          );
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '(${rating.toStringAsFixed(1)})',
            style: TextStyle(
              fontSize: size * 0.6,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

class RatingInputDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Function(int rating, String? comment) onSubmit;

  const RatingInputDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.onSubmit,
  });

  @override
  State<RatingInputDialog> createState() => _RatingInputDialogState();
}

class _RatingInputDialogState extends State<RatingInputDialog> {
  int _rating = 0;
  String _comment = '';
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // Comment Field
            TextField(
              controller: _commentController,
              onChanged: (value) {
                setState(() {
                  _comment = value;
                });
              },
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Comentario (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _rating > 0 
            ? () {
                widget.onSubmit(_rating, _comment.trim().isNotEmpty ? _comment.trim() : null);
                Navigator.of(context).pop();
              }
            : null,
          child: const Text('ENVIAR'),
        ),
      ],
    );
  }
}

class RatingDisplayWidget extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final Color color;
  final bool showCount;

  const RatingDisplayWidget({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.size = 20,
    this.color = Colors.amber,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor() 
              ? Icons.star 
              : index < rating 
                ? Icons.star_half 
                : Icons.star_border,
            color: color,
            size: size,
          );
        }),
        if (showCount && totalRatings > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalRatings)',
            style: TextStyle(
              fontSize: size * 0.6,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}