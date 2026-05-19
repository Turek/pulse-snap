import 'package:flutter/material.dart';

import '../../domain/tags/default_tags.dart';

/// Material 3 chip wrap for selecting reading tags.
///
/// Renders one [FilterChip] per default tag (plus any extra non-default
/// values present in [selected]), followed by a trailing `custom...`
/// [ActionChip]. Tapping `custom...` reveals an inline TextField + Add
/// button so the user can commit a free-form tag without a modal.
class TagChipRow extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final List<String> defaults;

  const TagChipRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.defaults = defaultTags,
  });

  @override
  State<TagChipRow> createState() => _TagChipRowState();
}

class _TagChipRowState extends State<TagChipRow> {
  final _controller = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isSelected(String tag) =>
      widget.selected.any((t) => t.toLowerCase() == tag.toLowerCase());

  void _toggle(String tag) {
    final next = {...widget.selected};
    final existing = next
        .where((t) => t.toLowerCase() == tag.toLowerCase())
        .toList();
    if (existing.isEmpty) {
      next.add(tag);
    } else {
      for (final e in existing) {
        next.remove(e);
      }
    }
    widget.onChanged(next);
  }

  void _addCustom() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    if (!_isSelected(raw)) {
      widget.onChanged({...widget.selected, raw});
    }
    _controller.clear();
    setState(() => _showCustomInput = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowerDefaults =
        widget.defaults.map((t) => t.toLowerCase()).toSet();
    final extras = widget.selected
        .where((t) => !lowerDefaults.contains(t.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final tag in widget.defaults)
              FilterChip(
                label: Text(tag),
                selected: _isSelected(tag),
                onSelected: (_) => _toggle(tag),
              ),
            for (final tag in extras)
              FilterChip(
                label: Text(tag),
                selected: true,
                onSelected: (_) => _toggle(tag),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('custom...'),
              onPressed: () =>
                  setState(() => _showCustomInput = !_showCustomInput),
            ),
          ],
        ),
        if (_showCustomInput) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustom(),
                  decoration: InputDecoration(
                    hintText: 'Custom tag',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _addCustom, child: const Text('Add')),
            ],
          ),
        ],
      ],
    );
  }
}
