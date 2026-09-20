import 'package:flutter/material.dart';

class DamageTypeInfo {
  final String icon;
  final Color color;
  const DamageTypeInfo({required this.icon, required this.color});
}

const Map<String, DamageTypeInfo> damageTypeInfo = {
  'Дробящий': DamageTypeInfo(icon: 'assets/Bludgeoning_Damage_Icon.webp', color: Color(0xFFD9D9D9)),
  'Колющий': DamageTypeInfo(icon: 'assets/Piercing_Damage_Icon.webp', color: Color(0xFFD9D9D9)),
  'Рубящий': DamageTypeInfo(icon: 'assets/Slashing_Damage_Icon.webp', color: Color(0xFFD9D9D9)),
  'Кислотный': DamageTypeInfo(icon: 'assets/Acid_Damage_Icon.webp', color: Color(0xFF73E600)),
  'Холод': DamageTypeInfo(icon: 'assets/Cold_Damage_Icon.webp', color: Color(0xFF00AEEF)),
  'Огонь': DamageTypeInfo(icon: 'assets/Fire_Damage_Icon.webp', color: Color(0xFFFF8C00)),
  'Силовой': DamageTypeInfo(icon: 'assets/Force_Damage_Icon.webp', color: Color(0xFFE65B5B)),
  'Электрический': DamageTypeInfo(icon: 'assets/Lightning_Damage_Icon.webp', color: Color(0xFF69B7D9)),
  'Некротический': DamageTypeInfo(icon: 'assets/Necrotic_Damage_Icon.webp', color: Color(0xFF58B77D)),
  'Ядовитый': DamageTypeInfo(icon: 'assets/Poison_Damage_Icon.webp', color: Color(0xFF72A82E)),
  'Психический': DamageTypeInfo(icon: 'assets/Psychic_Damage_Icon.webp', color: Color(0xFFD65CCF)),
  'Излучающий': DamageTypeInfo(icon: 'assets/Radiant_Damage_Icon.webp', color: Color(0xFFE8D96A)),
  'Звуковой': DamageTypeInfo(icon: 'assets/Thunder_Damage_Icon.webp', color: Color(0xFF9466CC)),
};