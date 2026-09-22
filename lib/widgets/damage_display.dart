import 'package:flutter/material.dart';
import '../utils/damage_type_info.dart';

String _formatDamage(int? diceMulti, String? diceName, int? dmgConst) {
  final dice = '${diceMulti ?? ''}${diceName ?? ''}';
  if (dmgConst == null || dmgConst == 0) return dice;
  final sign = dmgConst > 0 ? '+' : '';
  return '$dice$sign$dmgConst';
}

class DamagePiece extends StatelessWidget {
  final int? diceMulti;
  final String? diceName;
  final int? dmgConst;
  final String? damageType;

  const DamagePiece({super.key, this.diceMulti, this.diceName, this.dmgConst, this.damageType});

  @override
  Widget build(BuildContext context) {
    final info = damageTypeInfo[damageType];
    final text = _formatDamage(diceMulti, diceName, dmgConst);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (info != null) ...[Image.asset(info.icon, width: 18, height: 18), const SizedBox(width: 6)],
      Text(
        text.isNotEmpty ? text : '—',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: info?.color ?? Colors.white),
      ),
    ]);
  }
}

class DamageInline extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const DamageInline(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final sorted = [...rows]..sort((a, b) {
      final so = (a['sort_order'] as int? ?? 0).compareTo(b['sort_order'] as int? ?? 0);
      if (so != 0) return so;
      return (a['damage_type'] as String? ?? '').compareTo(b['damage_type'] as String? ?? '');
    });

    final children = <Widget>[];
    int? prevSortOrder;
    for (final r in sorted) {
      final so = r['sort_order'] as int?;
      if (prevSortOrder != null) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(so == prevSortOrder ? '/' : '+', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ));
      }
      children.add(DamagePiece(
        diceMulti: r['dice_multi'] as int?,
        diceName: r['dice_name'] as String?,
        dmgConst: r['dmg_const'] as int?,
        damageType: r['damage_type'] as String?,
      ));
      prevSortOrder = so;
    }
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }
}