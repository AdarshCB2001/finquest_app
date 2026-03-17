// City Screen — 3D isometric SimCity-style city view
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import '../widgets/city_painter.dart';

class CityScreen extends ConsumerStatefulWidget {
  const CityScreen({super.key});

  @override
  ConsumerState<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends ConsumerState<CityScreen> with SingleTickerProviderStateMixin {
  int _selectedIdx = -1;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse     = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(appProvider);
    final notifier = ref.read(appProvider.notifier);
    final buildings = state.buildings;
    final cityLevel = getCityLevel(buildings.length);
    final total     = buildings.fold<double>(0, (s, b) => s + b.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        children: [
          // ── CITY HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cityLevel.name, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 22)),
                Text('${buildings.length} buildings · ${fmtRupee(total)} invested',
                  style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
              ])),
              _StatBadge(icon: '🏗️', label: buildings.length.toString(), sublabel: 'buildings'),
              const SizedBox(width: 8),
              _StatBadge(
                icon: '⭐',
                label: buildings.where((b) => getBuildingTier(b.amount).index >= 4).length.toString(),
                sublabel: 'upgraded',
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // ── 3D CITY MAP ──
          GestureDetector(
            onTapDown: (details) => _handleTap(details, context, buildings),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(scale: _selectedIdx >= 0 ? 1.0 : 1.0, child: child),
              child: SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [Color(0xFF0D2137), Color(0xFF071525)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomPaint(
                      painter: CityIsometricPainter(buildings: buildings, selectedIndex: _selectedIdx),
                      child: buildings.isEmpty
                          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('🏗️', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text('Your city plot is ready!', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700)),
                              Text('Add a building below to break ground', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
                            ]))
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tap a building to add funds', style: TextStyle(color: AppTheme.text2, fontSize: 11), textAlign: TextAlign.center),
          ),

          // ── SELECTED BUILDING DETAIL ──
          if (_selectedIdx >= 0 && _selectedIdx < buildings.length) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SelectedBuildingCard(building: buildings[_selectedIdx], notifier: notifier, onClose: () => setState(() => _selectedIdx = -1)),
            ),
          ],

          // ── BUILDINGS LIST ──
          if (buildings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Your Buildings', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ...buildings.map((b) {
              final cat  = kBuildingCats[b.category] ?? kBuildingCats['house']!;
              final tier = getBuildingTier(b.amount);
              final next = tier.index < kBuildingTiers.length - 1 ? kBuildingTiers[tier.index + 1] : null;
              final pct  = next != null ? (b.amount - tier.minAmount) / (next.minAmount - tier.minAmount) : 1.0;
              final color = cat.color;
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final idx = buildings.indexOf(b);
                    setState(() => _selectedIdx = _selectedIdx == idx ? -1 : idx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: cat.bg, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.name, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600)),
                          Text('${cat.label} · ${tier.emoji} ${tier.name}', style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(fmtRupee(b.amount), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                          if (next != null)
                            Text('Next: ${fmtRupee(next.minAmount)}', style: const TextStyle(color: AppTheme.text2, fontSize: 10)),
                        ]),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.red, size: 18),
                          onPressed: () {
                            showDialog(context: context, builder: (_) => AlertDialog(
                              backgroundColor: AppTheme.card,
                              title: Text('Demolish ${b.name}?', style: const TextStyle(color: AppTheme.text1)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.text2))),
                                TextButton(onPressed: () { notifier.deleteBuilding(b.id); Navigator.pop(context); setState(() => _selectedIdx = -1); },
                                  child: const Text('Demolish', style: TextStyle(color: AppTheme.red))),
                              ],
                            ));
                          },
                        ),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: AppTheme.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(next != null ? '${(pct * 100).round()}% to ${next.name}' : '🏆 Fully upgraded!',
                        style: const TextStyle(color: AppTheme.text2, fontSize: 10), textAlign: TextAlign.right),
                    ]),
                  ),
                ),
              );
            }),
          ],

          // ── ADD BUILDING FORM ──
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Build New', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AddBuildingForm(),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _handleTap(TapDownDetails details, BuildContext ctx, List buildings) {
    // Simple tap detection — find nearest building to tapped point
    if (buildings.isEmpty) return;
    final localPos = details.localPosition;
    // Map screen pos back to approximate grid cell
    final cx = MediaQuery.of(ctx).size.width / 2;
    // Just cycle through buildings on tap for now
    setState(() => _selectedIdx = (_selectedIdx + 1) % buildings.length);
  }
}

class _StatBadge extends StatelessWidget {
  final String icon, label, sublabel;
  const _StatBadge({required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      Text(label, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 15)),
      Text(sublabel, style: const TextStyle(color: AppTheme.text2, fontSize: 9)),
    ]),
  );
}

class _SelectedBuildingCard extends StatefulWidget {
  final dynamic building;
  final dynamic notifier;
  final VoidCallback onClose;
  const _SelectedBuildingCard({required this.building, required this.notifier, required this.onClose});

  @override
  State<_SelectedBuildingCard> createState() => _SelectedBuildingCardState();
}

class _SelectedBuildingCardState extends State<_SelectedBuildingCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final b   = widget.building;
    final cat = kBuildingCats[b.category] ?? kBuildingCats['house']!;
    final tier = getBuildingTier(b.amount);
    final next = tier.index < kBuildingTiers.length - 1 ? kBuildingTiers[tier.index + 1] : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(cat.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(b.name, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.text2, size: 18), onPressed: widget.onClose),
          ]),
          Text('${tier.emoji} ${tier.name}  ·  ${fmtRupee(b.amount)}', style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
          if (next != null) Text('Next tier at ${fmtRupee(next.minAmount)}', style: TextStyle(color: cat.color, fontSize: 11)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Add funds (₹)', isDense: true, prefixText: '₹ '),
              style: const TextStyle(color: AppTheme.text1),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(_ctrl.text) ?? 0;
                if (amt <= 0) return;
                widget.notifier.addFundsToBuilding(b.id, amt);
                _ctrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${fmtRupee(amt)} to ${b.name}!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: cat.color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              child: const Text('Add'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _AddBuildingForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddBuildingForm> createState() => _AddBuildingFormState();
}

class _AddBuildingFormState extends ConsumerState<_AddBuildingForm> {
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _cat = 'house';

  @override
  void dispose() { _nameCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Category picker
      SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kBuildingCats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final entry = kBuildingCats.entries.elementAt(i);
            final isSelected = _cat == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _cat = entry.key),
              child: Container(
                width: 72, padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? entry.value.color.withOpacity(0.2) : AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? entry.value.color : AppTheme.border, width: isSelected ? 2 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(entry.value.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(entry.value.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                    color: isSelected ? entry.value.color : AppTheme.text2), textAlign: TextAlign.center),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 4),
      Text(kBuildingCats[_cat]?.desc ?? '', style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
      const SizedBox(height: 10),
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Building name'),
        style: const TextStyle(color: AppTheme.text1)),
      const SizedBox(height: 10),
      TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Starting amount (₹)', prefixText: '₹ '),
        style: const TextStyle(color: AppTheme.text1)),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final amt  = double.tryParse(_amountCtrl.text) ?? 0;
            if (name.isEmpty || amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name and amount > 0')));
              return;
            }
            ref.read(appProvider.notifier).addBuilding(name: name, category: _cat, amount: amt);
            _nameCtrl.clear(); _amountCtrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🏗️ ${getBuildingTier(amt).name} constructed!')));
          },
          icon: const Text('🏗️'),
          label: const Text('Build'),
        ),
      ),
    ]);
  }
}
