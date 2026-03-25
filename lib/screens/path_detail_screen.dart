import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/learning_path.dart';
import '../models/path_step.dart';
import '../widgets/step_bubble.dart';

class PathDetailScreen extends StatefulWidget {
  final LearningPath path;
  final ValueChanged<LearningPath> onPathUpdated;

  const PathDetailScreen({
    super.key,
    required this.path,
    required this.onPathUpdated,
  });

  @override
  State<PathDetailScreen> createState() => _PathDetailScreenState();
}

class _PathDetailScreenState extends State<PathDetailScreen> {
  late LearningPath _path;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _path = widget.path;
  }

  void _toggleStep(PathStep step) {
    final updatedSteps = _path.steps.map((s) {
      if (s.id == step.id) {
        return s.copyWith(isDone: !s.isDone);
      }
      return s;
    }).toList();

    setState(() {
      _path = LearningPath(
        id: _path.id,
        title: _path.title,
        dueDate: _path.dueDate,
        type: _path.type,
        theme: _path.theme,
        steps: updatedSteps,
      );
    });
    widget.onPathUpdated(_path);
  }

  void _addStep() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        final descController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                'Add step',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Step title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Optional description',
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
                    final title = controller.text.trim();
                    if (title.isEmpty) return;

                    final newStep = PathStep(
                      id: _uuid.v4(),
                      title: title,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );

                    setState(() {
                      _path = LearningPath(
                        id: _path.id,
                        title: _path.title,
                        dueDate: _path.dueDate,
                        type: _path.type,
                        theme: _path.theme,
                        steps: [..._path.steps, newStep],
                      );
                    });
                    widget.onPathUpdated(_path);
                    Navigator.of(ctx).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('Save step'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _dueText() {
    if (_path.dueDate == null) return 'No due date';
    final now = DateTime.now();
    final diff = _path.dueDate!.difference(now).inDays;
    if (diff < 0) return 'Due ${-diff} day(s) ago';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _path.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(_path.title),
      ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress == 0 ? 0.02 : progress,
                              strokeWidth: 6,
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _path.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dueText(),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_path.completedSteps}/${_path.totalSteps} steps done',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _path.steps.length,
                    itemBuilder: (ctx, index) {
                      final step = _path.steps[index];
                      final isLast =
                          index == _path.steps.length - 1;
                      return StepBubble(
                        step: step,
                        isLast: isLast,
                        onTap: () => _toggleStep(step),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStep,
        icon: const Icon(Icons.add),
        label: const Text('Add step'),
      ),
    );
  }
}
