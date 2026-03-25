import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/learning_path.dart';
import '../models/path_step.dart';
import 'new_path_screen.dart';
import 'path_detail_screen.dart';
import 'folder_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

/// One item on the home grid: either a single path or a folder of paths.
class _HomeTileData {
  final String id;
  final LearningPath? path;
  final List<LearningPath> folderPaths;
  final String? folderName;

  bool get isFolder => path == null && folderPaths.isNotEmpty;

  _HomeTileData.path(this.path)
      : id = path!.id,
        folderPaths = const [],
        folderName = null;

  _HomeTileData.folder({
    required this.id,
    required this.folderPaths,
    required this.folderName,
  }) : path = null;

  int get totalSteps {
    if (isFolder) {
      return folderPaths.fold<int>(0, (sum, p) => sum + p.totalSteps);
    }
    return path?.totalSteps ?? 0;
  }

  int get completedSteps {
    if (isFolder) {
      return folderPaths.fold<int>(0, (sum, p) => sum + p.completedSteps);
    }
    return path?.completedSteps ?? 0;
  }

  double get progress {
    final total = totalSteps;
    return total == 0 ? 0 : completedSteps / total;
  }

  String get title {
    if (isFolder) return folderName ?? 'Folder';
    return path?.title ?? '';
  }

  String get typeLabel {
    if (isFolder) return '${folderPaths.length} paths';
    return path?.type ?? 'Path';
  }

  DateTime? get dueDate {
    if (isFolder) {
      if (folderPaths.isEmpty) return null;
      folderPaths.sort((a, b) {
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
      return folderPaths.first.dueDate;
    }
    return path?.dueDate;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _TileUrgency {
  none,
  low,
  medium,
  high,
}

class _HomeScreenState extends State<HomeScreen> {
  final List<_HomeTileData> _tiles = [];
  final _uuid = const Uuid();
  int _folderCounter = 1;

  @override
  void initState() {
    super.initState();
    _seedDemoPath();
  }

  void _seedDemoPath() {
    final steps = [
      PathStep(
        id: _uuid.v4(),
        title: 'Re-read lectures 1–2',
        description: 'Focus on basic definitions & examples.',
      ),
      PathStep(
        id: _uuid.v4(),
        title: 'Do 10 practice questions',
      ),
      PathStep(
        id: _uuid.v4(),
        title: 'Past paper #1 (timed)',
      ),
    ];

    final path = LearningPath(
      id: _uuid.v4(),
      title: 'Algorithms midterm',
      dueDate: DateTime.now().add(const Duration(days: 10)),
      type: 'Exam',
      theme: 'sunset',
      steps: steps,
    );

    _tiles.add(_HomeTileData.path(path));
  }

  // ─────────────────────────────────────────────
  // URGENCY HELPERS
  // ─────────────────────────────────────────────

  _TileUrgency _urgencyForTile(_HomeTileData tile) {
    final due = tile.dueDate;
    if (due == null) return _TileUrgency.none;

    final now = DateTime.now();
    final diff = due.difference(now).inDays;

    if (diff < 0 || diff == 0) {
      return _TileUrgency.high; // overdue or today
    } else if (diff <= 3) {
      return _TileUrgency.medium;
    } else if (diff <= 7) {
      return _TileUrgency.low;
    } else {
      return _TileUrgency.none;
    }
  }

  Color? _colorForTileUrgency(_TileUrgency urgency) {
    switch (urgency) {
      case _TileUrgency.high:
        return Colors.redAccent;
      case _TileUrgency.medium:
        return Colors.orangeAccent;
      case _TileUrgency.low:
        return Colors.amber;
      case _TileUrgency.none:
        return null;
    }
  }

  // ─────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────

  void _openNewPath() async {
    final createdPath = await Navigator.of(context).push<LearningPath>(
      MaterialPageRoute(
        builder: (_) => const NewPathScreen(),
      ),
    );

    if (createdPath != null) {
      setState(() {
        _tiles.add(_HomeTileData.path(createdPath));
      });
    }
  }

  void _openTile(_HomeTileData tile) async {
    if (tile.isFolder) {
      final updatedPaths =
          await Navigator.of(context).push<List<LearningPath>>(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: FolderScreen(
                folderId: tile.id,
                folderName: tile.folderName ?? 'Folder',
                initialPaths: List.of(tile.folderPaths),
              ),
            );
          },
        ),
      );

      if (updatedPaths != null) {
        setState(() {
          final index = _tiles.indexWhere((t) => t.id == tile.id);
          if (index != -1) {
            _tiles[index] = _HomeTileData.folder(
              id: tile.id,
              folderPaths: updatedPaths,
              folderName: tile.folderName,
            );
          }
        });
      }
      return;
    }

    final path = tile.path!;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PathDetailScreen(
          path: path,
          onPathUpdated: (updated) {
            setState(() {
              final index =
                  _tiles.indexWhere((t) => t.path?.id == updated.id);
              if (index != -1) {
                _tiles[index] = _HomeTileData.path(updated);
              }
            });
          },
        ),
      ),
    );
  }

  void _openMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MapScreen(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DRAG + DROP MERGE
  // ─────────────────────────────────────────────

  Future<void> _onTileDroppedOnto({
    required _HomeTileData dragged,
    required _HomeTileData target,
  }) async {
    if (dragged.id == target.id) return;

    final shouldMerge = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create folder?'),
        content: Text(
          'Do you want to merge\n“${dragged.title}”\nwith\n“${target.title}”\ninto a folder?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (shouldMerge != true) return;

    setState(() {
      _tiles.removeWhere((t) => t.id == dragged.id || t.id == target.id);

      final List<LearningPath> paths = [];
      if (target.isFolder) {
        paths.addAll(target.folderPaths);
      } else if (target.path != null) {
        paths.add(target.path!);
      }
      if (dragged.isFolder) {
        paths.addAll(dragged.folderPaths);
      } else if (dragged.path != null) {
        paths.add(dragged.path!);
      }

      final folderName = 'Folder $_folderCounter';
      _folderCounter++;

      final folderTile = _HomeTileData.folder(
        id: _uuid.v4(),
        folderPaths: paths,
        folderName: folderName,
      );

      _tiles.add(folderTile);
    });
  }

  // ─────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────

  String _dueText(_HomeTileData tile) {
    final due = tile.dueDate;
    if (due == null) return 'No due date';
    final now = DateTime.now();
    final diff = due.difference(now).inDays;
    if (diff < 0) return 'Due ${-diff} day(s) ago';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  Widget _buildTile({
    required _HomeTileData tile,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final progress = tile.progress;

    final baseColor = tile.isFolder
        ? const Color(0xFFE0EAFF)
        : Colors.white.withOpacity(0.95);

    final urgency = _urgencyForTile(tile);
    final urgencyColor = _colorForTileUrgency(urgency);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isHighlighted ? baseColor.withOpacity(0.6) : baseColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: progress + type chip
          Row(
            children: [
              SizedBox(
                height: 34,
                width: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 4,
                      value: progress == 0 ? 0.02 : progress,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tile.typeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.deepPurple[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // title row with urgency dot (B2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (urgencyColor != null)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  tile.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),
          Text(
            _dueText(tile),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasTiles = _tiles.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pathboard'),
        actions: [
          IconButton(
            tooltip: 'Map',
            onPressed: _openMap,
            icon: const Icon(Icons.map_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your paths',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Drag tiles around. Drop one on another to merge into a folder ✨',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: hasTiles
                  ? GridView.builder(
                      itemCount: _tiles.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (ctx, index) {
                        final tile = _tiles[index];

                        return LongPressDraggable<_HomeTileData>(
                          data: tile,
                          feedback: Material(
                            color: Colors.transparent,
                            child: SizedBox(
                              width: 180,
                              height: 160,
                              child: _buildTile(tile: tile),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: DragTarget<_HomeTileData>(
                              builder: (context, candidate, rejected) {
                                return _buildTile(
                                  tile: tile,
                                  isHighlighted: candidate.isNotEmpty,
                                );
                              },
                            ),
                          ),
                          child: DragTarget<_HomeTileData>(
                            onWillAccept: (incoming) =>
                                incoming != null &&
                                incoming.id != tile.id,
                            onAccept: (incoming) => _onTileDroppedOnto(
                              dragged: incoming,
                              target: tile,
                            ),
                            builder: (context, candidate, rejected) {
                              final highlight = candidate.isNotEmpty;

                              Widget tileChild = _buildTile(
                                tile: tile,
                                isHighlighted: highlight,
                              );

                              if (tile.isFolder) {
                                tileChild = Hero(
                                  tag: 'folder_${tile.id}',
                                  child: tileChild,
                                );
                              }

                              return GestureDetector(
                                onTap: () => _openTile(tile),
                                child: tileChild,
                              );
                            },
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.landscape_rounded,
                            size: 80,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No paths yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first path and turn one scary deadline into a cute journey.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewPath,
        icon: const Icon(Icons.add),
        label: const Text('New path'),
      ),
    );
  }
}
