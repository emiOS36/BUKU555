import 'package:flutter/material.dart';

class PillToggleOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color color;

  const PillToggleOption({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });
}

class PillToggle<T> extends StatelessWidget {
  final List<PillToggleOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const PillToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length >= 2, 'Need at least 2 options');

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexWhere((o) => o.value == selected);
    assert(selectedIndex != -1, 'selected value is not in options');

    // Maps index 0..n-1 to alignment -1..1
    final alignX = -1 + 2 * selectedIndex / (options.length - 1);

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // Sliding pill
          AnimatedAlign(
            duration: _duration,
            curve: Curves.easeInOut,
            alignment: Alignment(alignX, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / options.length,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: _duration,
                decoration: BoxDecoration(
                  color: options[selectedIndex].color,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              for (final option in options)
                Expanded(
                  child: _Segment(
                    label: option.label,
                    icon: option.icon,
                    isActive: option.value == selected,
                    onTap: () => onChanged(option.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : Colors.grey.shade600;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
              ],
              AnimatedDefaultTextStyle(
                duration: PillToggle._duration,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
