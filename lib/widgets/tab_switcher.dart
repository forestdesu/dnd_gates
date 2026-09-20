import 'package:flutter/material.dart';

/// Переключатель вкладок с анимированным подчёркиванием.
class TabSwitcher extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const TabSwitcher({super.key, required this.labels, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromRGBO(37, 37, 39, 1.0),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(children: [
        Row(children: [for (var i = 0; i < labels.length; i++) Expanded(child: _label(i))]),
        const SizedBox(height: 8),
        AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment(labels.length > 1 ? -1 + 2 * selectedIndex / (labels.length - 1) : 0, 0),
          child: FractionallySizedBox(widthFactor: 1 / labels.length, child: Container(height: 2, color: Colors.red)),
        ),
      ]),
    );
  }

  Widget _label(int index) {
    final selected = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(color: selected ? Colors.white : Colors.white38, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 16),
            child: Text(labels[index]),
          ),
        ),
      ),
    );
  }
}