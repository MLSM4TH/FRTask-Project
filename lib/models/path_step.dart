class PathStep {
  final String id;
  final String title;
  final String? description;
  final DateTime? plannedDate;
  final bool isDone;

  PathStep({
    required this.id,
    required this.title,
    this.description,
    this.plannedDate,
    this.isDone = false,
  });

  PathStep copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? plannedDate,
    bool? isDone,
  }) {
    return PathStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      plannedDate: plannedDate ?? this.plannedDate,
      isDone: isDone ?? this.isDone,
    );
  }
}
