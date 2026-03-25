import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/learning_path.dart';
import '../models/path_step.dart';

class NewPathScreen extends StatefulWidget {
  const NewPathScreen({super.key});

  @override
  State<NewPathScreen> createState() => _NewPathScreenState();
}

class _NewPathScreenState extends State<NewPathScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _dueDate;
  String _type = 'Exam';
  final _uuid = const Uuid();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (result != null) {
      setState(() {
        _dueDate = result;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final path = LearningPath(
      id: _uuid.v4(),
      title: _titleController.text.trim(),
      dueDate: _dueDate,
      type: _type,
      theme: 'sunset',
      steps: [
        // For now, add 3 placeholder steps.
        PathStep(
          id: _uuid.v4(),
          title: 'Define scope',
          description: 'List topics/chapters included in this path.',
        ),
        PathStep(
          id: _uuid.v4(),
          title: 'First study block',
          description: 'Spend 45–60 minutes on the first chunk.',
        ),
        PathStep(
          id: _uuid.v4(),
          title: 'Past questions / practice',
          description: 'Try some practice problems or exercises.',
        ),
      ],
    );

    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New path'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you working towards?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Algorithms exam, DSP project, essay…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Give your path a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _buildTypeChip('Exam'),
                  _buildTypeChip('Project'),
                  _buildTypeChip('Essay'),
                  _buildTypeChip('Other'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'When is it due?',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'No date selected'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text('Pick date'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Create path ✨'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label) {
    final isSelected = _type == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _type = label;
        });
      },
      selectedColor: const Color(0xFF7C3AED).withOpacity(0.16),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4C1D95) : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
