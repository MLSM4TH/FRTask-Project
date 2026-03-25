import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../app_settings.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _PinTask {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String category; // Exam, Assignment, Project, Other

  _PinTask({
    required this.id,
    required this.title,
    required this.category,
    this.dueDate,
  });
}

class _Pin {
  final String id;
  final LatLng position;
  final String label;
  final String type; // Home, School, Work, Other
  final List<_PinTask> tasks;

  _Pin({
    required this.id,
    required this.position,
    required this.label,
    required this.type,
    List<_PinTask>? tasks,
  }) : tasks = tasks ?? [];
}

enum _PinUrgency {
  none,
  low,
  medium,
  high,
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userPos;
  bool _loadingLocation = true;
  bool _locationFailed = false;

  final List<_Pin> _pins = [];
  int _pinCounter = 1;
  int _taskCounter = 1;

  /// When true, we show a stronger heat-glow behind pins
  /// while the "My Day" sheet is open.
  bool _myDayHeatmapActive = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final settings = AppSettings.instance;

    // If user disabled location in settings, don't even try
    if (!settings.useLocation) {
      setState(() {
        _loadingLocation = false;
        _locationFailed = true;
      });
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loadingLocation = false;
          _locationFailed = true;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _locationFailed = true;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final center = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _userPos = center;
        _loadingLocation = false;
        _locationFailed = false;
      });

      _mapController.move(center, 15);
    } catch (_) {
      setState(() {
        _loadingLocation = false;
        _locationFailed = true;
      });
    }
  }

  // ─────────────────────────────────────────────
  // URGENCY HELPERS
  // ─────────────────────────────────────────────

  _PinUrgency _urgencyForPin(_Pin pin) {
    DateTime? soonest;

    for (final task in pin.tasks) {
      if (task.dueDate == null) continue;
      if (soonest == null || task.dueDate!.isBefore(soonest)) {
        soonest = task.dueDate!;
      }
    }

    if (soonest == null) return _PinUrgency.none;

    final now = DateTime.now();
    final diffDays = soonest.difference(now).inDays;

    if (diffDays < 0 || diffDays == 0) {
      // overdue or today
      return _PinUrgency.high;
    } else if (diffDays <= 3) {
      return _PinUrgency.medium;
    } else if (diffDays <= 7) {
      return _PinUrgency.low;
    } else {
      return _PinUrgency.none;
    }
  }

  Color? _colorForUrgency(_PinUrgency urgency) {
    switch (urgency) {
      case _PinUrgency.high:
        return Colors.redAccent;
      case _PinUrgency.medium:
        return Colors.orangeAccent;
      case _PinUrgency.low:
        return Colors.amber;
      case _PinUrgency.none:
        return null;
    }
  }

  // ─────────────────────────────────────────────
  // PIN CREATION
  // ─────────────────────────────────────────────

  void _onLongPress(TapPosition tapPos, LatLng latLng) async {
    String selectedType = 'Other';
    final labelController = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Text(
                    'Add a place',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Type',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Home'),
                        selected: selectedType == 'Home',
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = 'Home';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('School'),
                        selected: selectedType == 'School',
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = 'School';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Work'),
                        selected: selectedType == 'Work',
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = 'Work';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Other'),
                        selected: selectedType == 'Other',
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = 'Other';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label (e.g. “Campus library”)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('Save place'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _pins.add(
          _Pin(
            id: 'pin_${_pinCounter++}',
            position: latLng,
            label: labelController.text.trim().isEmpty
                ? selectedType
                : labelController.text.trim(),
            type: selectedType,
          ),
        );
      });
    }
  }

  // ─────────────────────────────────────────────
  // TASKS ON PINS
  // ─────────────────────────────────────────────

  Future<void> _showPinDetails(_Pin pin) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              void addTask() async {
                final newTask = await _createTaskDialog(ctx);
                if (newTask != null) {
                  setState(() {
                    pin.tasks.add(newTask);
                  });
                  setModalState(() {});
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    pin.label,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pin.type,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Tasks here',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: addTask,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add task'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pin.tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No tasks at this place yet. Maybe your future self will study here 👀',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pin.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final task = pin.tasks[index];
                        final dueText = _dueText(task.dueDate);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconForCategory(task.category),
                                size: 20,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    if (dueText != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        dueText,
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[700],
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () {
                                  setState(() {
                                    pin.tasks.removeAt(index);
                                  });
                                  setModalState(() {});
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<_PinTask?> _createTaskDialog(BuildContext ctx) async {
    final titleController = TextEditingController();
    DateTime? selectedDate;
    String category = 'Exam';

    return showDialog<_PinTask>(
      context: ctx,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add task'),
          content: StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              Future<void> pickDate() async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: dialogCtx,
                  initialDate: selectedDate ?? now,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now.add(const Duration(days: 365 * 3)),
                );
                if (picked != null) {
                  setDialogState(() {
                    selectedDate = picked;
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        hintText: 'e.g. “Algorithms midterm revision”',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Category',
                        style: Theme.of(dialogCtx).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Exam'),
                          selected: category == 'Exam',
                          onSelected: (_) {
                            setDialogState(() {
                              category = 'Exam';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Assignment'),
                          selected: category == 'Assignment',
                          onSelected: (_) {
                            setDialogState(() {
                              category = 'Assignment';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Project'),
                          selected: category == 'Project',
                          onSelected: (_) {
                            setDialogState(() {
                              category = 'Project';
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Other'),
                          selected: category == 'Other',
                          onSelected: (_) {
                            setDialogState(() {
                              category = 'Other';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'No due date'
                                : 'Due: ${_formatDate(selectedDate!)}',
                            style: Theme.of(dialogCtx)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: pickDate,
                          icon: const Icon(Icons.event_rounded),
                          label: const Text('Pick date'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.of(dialogCtx).pop(
                  _PinTask(
                    id: 'task_${_taskCounter++}',
                    title: title,
                    category: category,
                    dueDate: selectedDate,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String? _dueText(DateTime? due) {
    if (due == null) return null;
    final now = DateTime.now();
    final diffDays = due.difference(now).inDays;

    if (diffDays < 0) {
      return 'Due ${-diffDays} day(s) ago';
    } else if (diffDays == 0) {
      return 'Due today';
    } else if (diffDays == 1) {
      return 'Due tomorrow';
    } else if (diffDays <= 7) {
      return 'Due in $diffDays days';
    } else {
      return 'Due ${_formatDate(due)}';
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Exam':
        return Icons.quiz_rounded;
      case 'Assignment':
        return Icons.description_rounded;
      case 'Project':
        return Icons.hub_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  // ─────────────────────────────────────────────
  // "MY DAY" / STICKMAN SUMMARY + HEATMAP
  // ─────────────────────────────────────────────

  void _openMyDay() {
    final allTasks = <_PinTask, _Pin>{};

    for (final pin in _pins) {
      for (final task in pin.tasks) {
        allTasks[task] = pin;
      }
    }

    if (allTasks.isEmpty) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  'Nothing planned yet',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Long-press the map to add study spots and attach tasks to them.',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    final tasksSorted = allTasks.keys.toList()
      ..sort((a, b) {
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });

    setState(() {
      _myDayHeatmapActive = true;
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                'Today & soon',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'What you have coming up across your places',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tasksSorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final task = tasksSorted[index];
                    final pin = allTasks[task]!;
                    final dueText = _dueText(task.dueDate);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _iconForCategory(task.category),
                            size: 20,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pin.label,
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[800],
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                                if (dueText != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    dueText,
                                    style: Theme.of(ctx)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _myDayHeatmapActive = false;
      });
    });
  }

  // ─────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────

  void _openBoard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
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
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = _userPos ?? const LatLng(0, 0);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _userPos != null ? 13 : 2,
              onLongPress: _onLongPress,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pathboard',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Aesthetic gradient overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.transparent,
                    Colors.white.withOpacity(0.25),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Header with title + settings + location status
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_rounded,
                          size: 18,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your world',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.white.withOpacity(0.9),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.all(6),
                      ),
                    ),
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  if (_loadingLocation)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('Locating…'),
                        ],
                      ),
                    )
                  else if (_locationFailed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Location unavailable',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Hint bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Long-press anywhere to add a place ✨',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ),

          // Button to go to Pathboard (home tiles)
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.extended(
              heroTag: 'to_board',
              onPressed: _openBoard,
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: const Text('Board'),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // User position stickman
    if (_userPos != null) {
      markers.add(
        Marker(
          point: _userPos!,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: _openMyDay, // ⬅️ tap stickman = "My day"
            child: const Icon(
              Icons.accessibility_new_rounded,
              size: 36,
              color: Colors.deepPurple,
            ),
          ),
        ),
      );
    }

    // Pins with urgency halo and optional heat-glow
    for (final pin in _pins) {
      IconData icon;
      Color baseColor;

      switch (pin.type) {
        case 'Home':
          icon = Icons.home_rounded;
          baseColor = Colors.pinkAccent;
          break;
        case 'School':
          icon = Icons.school_rounded;
          baseColor = Colors.blueAccent;
          break;
        case 'Work':
          icon = Icons.apartment_rounded;
          baseColor = Colors.teal;
          break;
        default:
          icon = Icons.place_rounded;
          baseColor = Colors.orangeAccent;
      }

      final urgency = _urgencyForPin(pin);
      final urgencyColor = _colorForUrgency(urgency);

      markers.add(
        Marker(
          point: pin.position,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showPinDetails(pin),
            child: Tooltip(
              message: pin.label,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Heatmap-like big glow when My Day is open
                  if (_myDayHeatmapActive && pin.tasks.isNotEmpty)
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (urgencyColor ?? baseColor)
                            .withOpacity(0.18),
                      ),
                    ),
                  // Urgency halo (A1)
                  if (urgencyColor != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: urgency == _PinUrgency.high
                          ? 46
                          : urgency == _PinUrgency.medium
                              ? 42
                              : 38,
                      height: urgency == _PinUrgency.high
                          ? 46
                          : urgency == _PinUrgency.medium
                              ? 42
                              : 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: urgencyColor.withOpacity(0.35),
                      ),
                    ),
                  // Pin icon itself
                  Icon(
                    icon,
                    size: 32,
                    color: baseColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }
}
