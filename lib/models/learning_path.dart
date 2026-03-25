import 'path_step.dart';

class LearningPath {
  final String id;
  final String title;
  final DateTime? dueDate;
  final String type; // "Exam", "Project", etc.
  final String theme; // e.g. "sunset", "galaxy"
  final List<PathStep> steps;

  LearningPath({
    required this.id,
    required this.title,
    this.dueDate,
    this.type = "Exam",
    this.theme = "sunset",
    this.steps = const [],
  });

  int get totalSteps => steps.length;

  int get completedSteps =>
      steps.where((step) => step.isDone).length;

  double get progress =>
      totalSteps == 0 ? 0 : completedSteps / totalSteps;
}
