// lib/screens/ratings/ratings_screen.dart
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/rating.dart';
import '../../services/rating_service.dart';

class RatingsScreen extends StatefulWidget {
  final User user;
  const RatingsScreen({super.key, required this.user});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<Rating> _ratings = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _ratings.clear();
        _hasMore = true;
      }
    });

    try {
      final result = await RatingService.getUserRatings(
        userId: widget.user.id,
        page: _currentPage,
        limit: _limit,
      );

      if (result['success'] && mounted) {
        final data = result['data'];
        final newRatings = (data['ratings'] as List)
            .map((r) => Rating.fromJson(r))
            .toList();

        setState(() {
          if (refresh) {
            _ratings = newRatings;
          } else {
            _ratings.addAll(newRatings);
          }
          _hasMore = data['pagination']['hasNext'] ?? false;
          _currentPage++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar calificaciones: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calificaciones de ${widget.user.firstName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadRatings(refresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadRatings(refresh: true),
        child: Column(
          children: [
            // Header con información del usuario y promedio
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.user.profilePhoto != 'default_avatar.png'
                        ? NetworkImage(widget.user.profilePhoto)
                        : null,
                    child: widget.user.profilePhoto == 'default_avatar.png'
                        ? Text(widget.user.initials)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.user.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 4),
                            ...List.generate(5, (index) {
                              return Icon(
                                index < widget.user.averageRating.floor() 
                                  ? Icons.star 
                                  : index < widget.user.averageRating 
                                    ? Icons.star_half 
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ],
                        ),
                        if (widget.user.hasRatings) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.user.averageRatingText,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Lista de calificaciones
            Expanded(
              child: _ratings.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin calificaciones',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este usuario aún no tiene calificaciones',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _ratings.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _ratings.length) {
                          if (_hasMore) {
                            _loadRatings();
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final rating = _ratings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Usuario ${rating.raterId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < rating.rating 
                                            ? Icons.star 
                                            : Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    rating.comment!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Hace ${_getTimeAgo(rating.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays != 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours != 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes != 1 ? 's' : ''}';
    } else {
      return 'hace un momento';
    }
  }
}


