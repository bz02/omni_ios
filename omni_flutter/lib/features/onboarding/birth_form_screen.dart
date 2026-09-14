/// Collects the birth record that everything else is computed from.
///
/// The whole app depends on these four fields, so the form is built around not
/// losing people at it:
///   * no account, no email, no password — that comes later, if ever
///   * "I don't know my birth time" is a first-class answer, because roughly
///     half the audience genuinely does not, and refusing them is a conversion
///     problem rather than an accuracy win
///   * the UTC offset is shown and editable, because summer time is a fact only
///     the user knows and guessing it wrong moves a rising sign a whole sign
library;

import 'package:flutter/material.dart';

import '../../core/data/cities.dart';
import '../../core/engine/soul_blueprint.dart';
import '../../core/theme/modern_theme.dart';

class BirthFormScreen extends StatefulWidget {
  const BirthFormScreen({
    super.key,
    this.initial,
    this.title = 'Your birth moment',
    this.subtitle =
        'Two charts come out of this. Nothing leaves your phone.',
    this.askForName = false,
  });

  final BirthData? initial;
  final String title;
  final String subtitle;

  /// Set when adding someone else for a compatibility check.
  final bool askForName;

  @override
  State<BirthFormScreen> createState() => _BirthFormScreenState();
}

class _BirthFormScreenState extends State<BirthFormScreen> {
  late DateTime _date;
  TimeOfDay? _time;
  City? _city;
  double? _offsetOverride;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _date = initial?.localDateTime ?? DateTime(1995, 6, 15);
    _time = initial != null && initial.timeIsKnown
        ? TimeOfDay(
            hour: initial.localDateTime.hour,
            minute: initial.localDateTime.minute)
        : null;
    if (initial?.placeName != null) {
      _city = cityByLabel(initial!.placeName!);
    }
    _offsetOverride = initial?.utcOffsetHours;
    _nameController.text = initial?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _effectiveOffset =>
      _offsetOverride ?? _city?.standardUtcOffset ?? 0;

  bool get _canSubmit =>
      _city != null && (!widget.askForName || _nameController.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(widget.subtitle, style: ModernTheme.body),
          const SizedBox(height: 24),
          if (widget.askForName) ...[
            const _FieldLabel('Their name'),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Who is this?',
                filled: true,
                fillColor: ModernTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: ModernTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: ModernTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const _FieldLabel('Date of birth'),
          _Row(
            value: '${_date.year}-${_two(_date.month)}-${_two(_date.day)}',
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Time of birth'),
          _Row(
            value: _time == null
                ? 'I do not know'
                : '${_two(_time!.hour)}:${_two(_time!.minute)}',
            icon: Icons.schedule_outlined,
            onTap: _pickTime,
            trailing: _time == null
                ? null
                : TextButton(
                    onPressed: () => setState(() => _time = null),
                    child: const Text('Clear'),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            _time == null
                ? 'Without a time we leave out the Moon, the rising sign and the '
                    'hour pillar rather than guessing at them.'
                : 'Even fifteen minutes moves the rising sign, so use the birth '
                    'certificate if you have it.',
            style: ModernTheme.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Place of birth'),
          _Row(
            value: _city?.label ?? 'Choose a city',
            icon: Icons.public,
            onTap: _pickCity,
          ),
          if (_city != null) ...[
            const SizedBox(height: 20),
            const _FieldLabel('Clock offset from UTC'),
            _OffsetPicker(
              value: _effectiveOffset,
              standard: _city!.standardUtcOffset,
              onChanged: (v) => setState(() => _offsetOverride = v),
            ),
            if (_city!.observesSummerTime)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_city!.country} uses summer time. If you were born in the '
                  'summer months, add an hour.',
                  style: ModernTheme.caption
                      .copyWith(fontSize: 12, color: ModernTheme.gold),
                ),
              ),
          ],
          const SizedBox(height: 28),
          if (_city != null) _Preview(birth: _buildBirthData()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSubmit
                ? () => Navigator.of(context).pop(_buildBirthData())
                : null,
            child: const Text('Read my chart'),
          ),
        ),
      ),
    );
  }

  BirthData _buildBirthData() => BirthData(
        localDateTime: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time?.hour ?? 0,
          _time?.minute ?? 0,
        ),
        utcOffsetHours: _effectiveOffset,
        latitudeNorth: _city?.latitude,
        longitudeEast: _city?.longitude,
        placeName: _city?.label,
        timeIsKnown: _time != null,
        displayName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Time of birth',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CityPicker(),
    );
    if (picked != null) {
      setState(() {
        _city = picked;
        _offsetOverride = null;
      });
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: ModernTheme.caption.copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.value,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: ModernTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ModernTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ModernTheme.textSub),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value,
                    style: ModernTheme.body
                        .copyWith(color: ModernTheme.textMain)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}

class _OffsetPicker extends StatelessWidget {
  const _OffsetPicker({
    required this.value,
    required this.standard,
    required this.onChanged,
  });

  final double value;
  final double standard;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final isOverridden = value != standard;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: ModernTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModernTheme.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          Expanded(
            child: Column(
              children: [
                Text(_format(value),
                    style: ModernTheme.subHeader.copyWith(fontSize: 18)),
                Text(
                  isOverridden ? 'adjusted' : 'standard time',
                  style: ModernTheme.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  static String _format(double offset) {
    final sign = offset < 0 ? '-' : '+';
    final abs = offset.abs();
    final hours = abs.floor();
    final minutes = ((abs - hours) * 60).round();
    return 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }
}

/// Shows what the entered data resolves to before the user commits, so a typo
/// in the year is caught here rather than after a whole reading.
class _Preview extends StatelessWidget {
  const _Preview({required this.birth});
  final BirthData birth;

  @override
  Widget build(BuildContext context) {
    final blueprint = computeSoulBlueprint(birth);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ModernTheme.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREVIEW',
              style: ModernTheme.caption.copyWith(
                fontSize: 10,
                letterSpacing: 2,
                color: ModernTheme.jade,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 10),
          Text(
            blueprint.western.bigThree,
            style: ModernTheme.subHeader.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            blueprint.bazi.pillars.map((p) => p.chinese).join('  '),
            style: ModernTheme.subHeader.copyWith(
              color: ModernTheme.gold,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${blueprint.bazi.zodiacAnimal} · '
            '${blueprint.bazi.dayMaster.element.english} day master · '
            '${blueprint.bazi.year.naYin.english}',
            style: ModernTheme.caption.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CityPicker extends StatefulWidget {
  const _CityPicker();

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = searchCities(_query, limit: 60);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search a city',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No match. Pick the nearest large city — a hundred '
                          'kilometres moves the ascendant by less than a degree.',
                          textAlign: TextAlign.center,
                          style: ModernTheme.caption,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final city = results[index];
                        return ListTile(
                          title: Text(city.name),
                          subtitle: Text(city.country),
                          trailing: Text(
                            _OffsetPicker._format(city.standardUtcOffset),
                            style: ModernTheme.caption,
                          ),
                          onTap: () => Navigator.of(context).pop(city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
