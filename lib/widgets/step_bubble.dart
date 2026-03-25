import 'package:flutter/material.dart';
import '../models/path_step.dart';

class StepBubble extends StatelessWidget {
  final PathStep step;
  final bool isLast;
  final VoidCallback? onTap;

  const StepBubble({
    super.key,
    required this.step,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = step.isDone;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line + dot
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF22C55E)
                      : Colors.white,
                  border: Border.all(
                    color: done
                        ? const Color(0xFF16A34A)
                        : Colors.deepPurple.shade200,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.deepPurple.shade100,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: done
                    ? const Color(0xFFE9FCEB)
                    : Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          done ? TextDecoration.lineThrough : null,
                      color: done
                          ? Colors.grey[700]
                          : const Color(0xFF111827),
                    ),
                  ),
                  if (step.description != null &&
                      step.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  if (step.plannedDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${step.plannedDate!.day}/${step.plannedDate!.month}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
