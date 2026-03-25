import 'package:flutter/material.dart';

import '../models/learning_path.dart';
import 'path_detail_screen.dart';

class FolderScreen extends StatefulWidget {
  final String folderId;        // 👈 hero tag id
  final String folderName;
  final List<LearningPath> initialPaths;

  const FolderScreen({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.initialPaths,
  });

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  late List<LearningPath> _paths;

  @override
  void initState() {
    super.initState();
    _paths = List.of(widget.initialPaths);
  }

  void _openPath(LearningPath path) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PathDetailScreen(
          path: path,
          onPathUpdated: (updated) {
            setState(() {
              final idx = _paths.indexWhere((p) => p.id == updated.id);
              if (idx != -1) {
                _paths[idx] = updated;
              }
            });
          },
        ),
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_paths); // send updated paths back
  }

  String _dueText(LearningPath path) {
    if (path.dueDate == null) return 'No due date';
    final now = DateTime.now();
    final diff = path.dueDate!.difference(now).inDays;
    if (diff < 0) return 'Due ${-diff} day(s) ago';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFDF2FF),
              Color(0xFFE5F3FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Hero(
              tag: 'folder_${widget.folderId}',      // 👈 same tag as home
              // This container animates from the tile to fullscreen
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar inside hero card
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: _close,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.folderName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Paths in this folder',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: _paths.isEmpty
                              ? Center(
                                  child: Text(
                                    'This folder is empty.',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _paths.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (ctx, index) {
                                    final path = _paths[index];
                                    final progress = path.progress;

                                    return GestureDetector(
                                      onTap: () => _openPath(path),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.04),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: Stack(
                                                alignment:
                                                    Alignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    strokeWidth: 4,
                                                    value: progress == 0
                                                        ? 0.02
                                                        : progress,
                                                  ),
                                                  Text(
                                                    '${(progress * 100).round()}%',
                                                    style:
                                                        const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    path.title,
                                                    style: theme
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      height: 4),
                                                  Text(
                                                    _dueText(path),
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                      color: Colors
                                                          .grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
