// VISS KODS LATVIEŠU KOMENTĀROS – UI teksti latviski/angliski, kods angliski.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// ===== Modeļi =====
enum TaskPriority { high, medium, low, none }
enum TaskCategory { visi, darbs, personigs, labasDomas, dzimsanasDienas }

class TaskItem {
  TaskItem({
    required this.title,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.dueDate,
    this.completed = false,
  });

  String title;
  TaskCategory category;
  TaskPriority priority;
  DateTime createdAt;
  DateTime? dueDate;
  bool completed;
}

Color priorityColor(TaskPriority p, ColorScheme cs) {
  switch (p) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.amber;
    case TaskPriority.low:
      return Colors.blue;
    case TaskPriority.none:
      return cs.outline;
  }
}

const Map<TaskCategory, String> kCategoryNameLV = {
  TaskCategory.visi: 'Visi',
  TaskCategory.darbs: 'Darbs',
  TaskCategory.personigs: 'Personīgs',
  TaskCategory.labasDomas: 'Labas domas',
  TaskCategory.dzimsanasDienas: 'Dzimšanas dienas',
};

const Map<TaskCategory, String> kCategoryNameEN = {
  TaskCategory.visi: 'All',
  TaskCategory.darbs: 'Work',
  TaskCategory.personigs: 'Personal',
  TaskCategory.labasDomas: 'Good ideas',
  TaskCategory.dzimsanasDienas: 'Birthdays',
};

void main() {
  Intl.defaultLocale = 'lv';
  runApp(const AppRoot());
}

// ===== App ar pārslēdzamu locale =====
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Locale _locale = const Locale('lv');

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF2563EB),
      brightness: Brightness.light,
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Totalist',
      locale: _locale,
      supportedLocales: const [Locale('lv'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: base.colorScheme.onSurface,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
        ),
      ),
      home: HomeShell(
        locale: _locale,
        onChangeLocale: (l) => setState(() => _locale = l),
      ),
    );
  }
}

// ===== Home ar divām cilnēm =====
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.locale, required this.onChangeLocale});
  final Locale locale;
  final void Function(Locale) onChangeLocale;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final List<TaskItem> _items = [];
  bool _completedExpanded = false;
  bool _sortByPriorityThenAlpha = true;

  // Čipu “izvērst/sakļaut”
  bool _chipsExpanded = false;

  // Kalendārs
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Atlasītā kategorija
  TaskCategory _selectedCat = TaskCategory.visi;

  bool get isLV => widget.locale.languageCode == 'lv';
  bool get isEN => widget.locale.languageCode == 'en';

  Map<TaskCategory, String> get catNames =>
      isLV ? kCategoryNameLV : kCategoryNameEN;

  String t(String lv, String en) => isLV ? lv : en;

  // ===== Filtri un kārtošana =====
  List<TaskItem> _visibleActiveItems() {
    final xs = _items.where((t) => !t.completed && _categoryFilter(t)).toList();
    _sort(xs);
    return xs;
  }

  List<TaskItem> _visibleCompletedItems() {
    final xs = _items.where((t) => t.completed && _categoryFilter(t)).toList();
    _sort(xs);
    return xs;
  }

  bool _categoryFilter(TaskItem t) {
    if (_selectedCat == TaskCategory.visi) return true;
    return t.category == _selectedCat;
  }

  void _sort(List<TaskItem> list) {
    int p(TaskPriority pr) {
      switch (pr) {
        case TaskPriority.high:
          return 0;
        case TaskPriority.medium:
          return 1;
        case TaskPriority.low:
          return 2;
        case TaskPriority.none:
          return 3;
      }
    }

    list.sort((a, b) {
      if (_sortByPriorityThenAlpha) {
        final byP = p(a.priority).compareTo(p(b.priority));
        if (byP != 0) return byP;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  }

  // Kalendāra “eventi” (punkti)
  List<TaskItem> _eventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _items.where((t) {
      if (t.dueDate == null) return false;
      final x = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return x == d;
    }).toList();
  }

  // Pievienot
  Future<void> _openQuickAdd({DateTime? presetDate}) async {
    final result = await showModalBottomSheet<TaskItem>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _AddTaskSheet(
          presetCategory: _selectedCat == TaskCategory.visi
              ? TaskCategory.darbs
              : _selectedCat,
          presetDate: presetDate,
          isLV: isLV,
        ),
      ),
    );

    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  void _toggleCompleted(TaskItem t) => setState(() => t.completed = !t.completed);
  void _setPriority(TaskItem t, TaskPriority p) => setState(() => t.priority = p);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final pages = [
      _buildTasksPage(context, cs),
      _buildCalendarPage(context, cs),
    ];

    final titles = [
      t('Totalist · Uzdevumi', 'Totalist · Tasks'),
      t('Totalist · Kalendārs', 'Totalist · Calendar'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          // Locale switcher
          IconButton(
            tooltip: t('Mainīt valodu', 'Change language'),
            onPressed: () async {
              final choice = await showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                items: [
                  PopupMenuItem(value: 'lv', child: const Text('Latviešu')),
                  PopupMenuItem(value: 'en', child: const Text('English')),
                ],
              );
              if (choice == 'lv') widget.onChangeLocale(const Locale('lv'));
              if (choice == 'en') widget.onChangeLocale(const Locale('en'));
            },
            icon: const Icon(Icons.language),
          ),
          if (_tab == 0) ...[
            // Kārtošanas slēdzis ar maināmu ikonu
            IconButton(
              tooltip: _sortByPriorityThenAlpha
                  ? t('Kārtošana: prioritātes → alfabēts',
                      'Sort: priority → A–Z')
                  : t('Kārtošana: alfabēts', 'Sort: A–Z'),
              onPressed: () =>
                  setState(() => _sortByPriorityThenAlpha = !_sortByPriorityThenAlpha),
              icon: Icon(
                _sortByPriorityThenAlpha ? Icons.flag_outlined : Icons.sort_by_alpha,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'toggle_completed':
                    setState(() => _completedExpanded = !_completedExpanded);
                    break;
                  case 'clear_completed':
                    setState(() => _items.removeWhere((t) => t.completed));
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'toggle_completed',
                  child: Text(_completedExpanded
                      ? t('Slēgt “Pabeigtie”', 'Collapse “Completed”')
                      : t('Atvērt “Pabeigtie”', 'Expand “Completed”')),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear_completed',
                  child: Text(t('Iztīrīt pabeigtos', 'Clear completed')),
                ),
              ],
            ),
          ],
        ],
      ),
      body: pages[_tab],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tab == 0) {
            _openQuickAdd();
          } else {
            _openQuickAdd(presetDate: _selectedDay ?? _focusedDay);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(t('Pievienot', 'Add')),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist),
            label: t('Uzdevumi', 'Tasks'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            label: t('Kalendārs', 'Calendar'),
          ),
        ],
      ),
      backgroundColor: cs.surface.withValues(alpha: 0.98),
    );
  }

  // ===== Uzdevumu lapa =====
  Widget _buildTasksPage(BuildContext context, ColorScheme cs) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildCategoryChips(context),
            const SizedBox(height: 16),
            Expanded(child: _buildTaskLists(context, cs)),
          ],
        ),
      ),
    );
  }

  // Kategoriju josla ar kompaktu/plašu režīmu
  Widget _buildCategoryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = TaskCategory.values;

    IconData iconFor(TaskCategory c) {
      switch (c) {
        case TaskCategory.visi:
          return Icons.all_inbox_outlined;
        case TaskCategory.darbs:
          return Icons.work_outline;
        case TaskCategory.personigs:
          return Icons.person_outline;
        case TaskCategory.labasDomas:
          return Icons.lightbulb_outline;
        case TaskCategory.dzimsanasDienas:
          return Icons.cake_outlined;
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in cats)
            GestureDetector(
              onLongPress: () => setState(() => _chipsExpanded = !_chipsExpanded),
              child: FilterChip(
                label: _chipsExpanded ? Text(catNames[c]!) : const Text(''),
                avatar: Icon(iconFor(c)),
                selected: _selectedCat == c,
                onSelected: (_) => setState(() => _selectedCat = c),
                showCheckmark: false,
                side: BorderSide(
                  color:
                      _selectedCat == c ? cs.primary : cs.outlineVariant,
                ),
                backgroundColor:
                    _chipsExpanded ? cs.surfaceContainer : cs.surfaceContainerHigh,
                selectedColor:
                    _chipsExpanded ? cs.primaryContainer : cs.primaryContainer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ActionChip(
            avatar:
                Icon(_chipsExpanded ? Icons.unfold_less : Icons.unfold_more),
            label: Text(_chipsExpanded ? t('Sakļaut', 'Collapse')
                                       : t('Izvērst', 'Expand')),
            onPressed: () => setState(() => _chipsExpanded = !_chipsExpanded),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskLists(BuildContext context, ColorScheme cs) {
    final active = _visibleActiveItems();
    final completed = _visibleCompletedItems();

    return ListView(
      children: [
        if (active.isNotEmpty)
          ...active.map((t) => _TaskTile(
                item: t,
                onToggleDone: () => _toggleCompleted(t),
                onSetPriority: (p) => _setPriority(t, p),
              ))
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(t('Nav uzdevumu. Pievieno jaunu!',
                                         'No tasks. Add one!'))),
          ),
        const SizedBox(height: 16),
        ExpansionTile(
          initiallyExpanded: _completedExpanded,
          onExpansionChanged: (v) => setState(() => _completedExpanded = v),
          title: Text(t('Pabeigtie', 'Completed')),
          children: completed.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(t('Šobrīd nav pabeigtu uzdevumu.',
                                   'No completed tasks.')),
                  )
                ]
              : completed
                  .map((t) => _TaskTile(
                        item: t,
                        onToggleDone: () => _toggleCompleted(t),
                        onSetPriority: (p) => _setPriority(t, p),
                      ))
                  .toList(),
        ),
      ],
    );
  }

  // ===== Kalendāra lapa =====
  Widget _buildCalendarPage(BuildContext context, ColorScheme cs) {
    // LV: nedēļa no pirmdienas; EN: no svētdienas
    final start = isEN ? StartingDayOfWeek.sunday : StartingDayOfWeek.monday;

    String dowOneLetter(DateTime date, String? locale) {
      // 1=Mon ... 7=Sun
      final w = date.weekday;
      if (isLV) {
        // P O T C P S Sv
        switch (w) {
          case DateTime.monday:
            return 'P';
          case DateTime.tuesday:
            return 'O';
          case DateTime.wednesday:
            return 'T';
          case DateTime.thursday:
            return 'C';
          case DateTime.friday:
            return 'P';
          case DateTime.saturday:
            return 'S';
          case DateTime.sunday:
            return 'Sv';
        }
      }
      // EN: S M T W T F S
      switch (w) {
        case DateTime.sunday:
          return 'S';
        case DateTime.monday:
          return 'M';
        case DateTime.tuesday:
          return 'T';
        case DateTime.wednesday:
          return 'W';
        case DateTime.thursday:
          return 'T';
        case DateTime.friday:
          return 'F';
        case DateTime.saturday:
          return 'S';
      }
      return '';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TableCalendar<TaskItem>(
              locale: widget.locale.languageCode,
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2050, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) =>
                  _selectedDay != null &&
                  d.year == _selectedDay!.year &&
                  d.month == _selectedDay!.month &&
                  d.day == _selectedDay!.day,
              onDaySelected: (sel, foc) {
                setState(() {
                  _selectedDay = sel;
                  _focusedDay = foc;
                });
              },
              eventLoader: _eventsForDay,
              calendarFormat: _calendarFormat,
              onFormatChanged: (f) => setState(() => _calendarFormat = f),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonTextStyle:
                    TextStyle(color: cs.onPrimaryContainer),
                formatButtonDecoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              startingDayOfWeek: start,
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) =>
                    dowOneLetter(date, locale),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  border: Border.all(color: cs.primary, width: 2),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Saraksts zem kalendāra (atlasītā diena)
            Expanded(
              child: Builder(builder: (ctx) {
                final day = _selectedDay ?? _focusedDay;
                final es = _eventsForDay(day);
                if (es.isEmpty) {
                  return Center(
                    child: Text(t('Šajā dienā nav uzdevumu.',
                                   'No tasks on this day.')),
                  );
                }
                return ListView.separated(
                  itemCount: es.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = es[i];
                    return _TaskTile(
                      item: t,
                      onToggleDone: () => _toggleCompleted(t),
                      onSetPriority: (p) => _setPriority(t, p),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Viena uzdevuma flīze =====
class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.item,
    required this.onToggleDone,
    required this.onSetPriority,
  });

  final TaskItem item;
  final VoidCallback onToggleDone;
  final void Function(TaskPriority) onSetPriority;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleStyle = item.completed
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: cs.onSurface.withValues(alpha: 0.5),
          )
        : null;

    final flag = item.completed ? TaskPriority.none : item.priority;
    final flagColor = priorityColor(flag, cs);

    final due = item.dueDate != null
        ? DateFormat('d. MMM, EEE').format(item.dueDate!)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggleDone,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              // Karodziņa punkts
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: item.completed ? Colors.transparent : flagColor,
                  border: Border.all(color: flagColor, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              // Teksti
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: titleStyle),
                    if (due != null)
                      Text(
                        'Termiņš: $due',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Prioritātes izvēlne
              PopupMenuButton<TaskPriority>(
                tooltip: 'Prioritāte',
                onSelected: onSetPriority,
                itemBuilder: (_) => [
                  _prioItem(TaskPriority.high, 'Augsta', Colors.red),
                  _prioItem(TaskPriority.medium, 'Vidēja', Colors.amber),
                  _prioItem(TaskPriority.low, 'Zema', Colors.blue),
                  _prioItem(TaskPriority.none, 'Nav', cs.outline),
                ],
                icon: const Icon(Icons.more_vert),
              ),
              Checkbox(value: item.completed, onChanged: (_) => onToggleDone()),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<TaskPriority> _prioItem(
      TaskPriority p, String title, Color c) {
    return PopupMenuItem(
      value: p,
      child: Row(
        children: [
          Icon(Icons.flag, size: 18, color: c),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
}

// ===== Apakšējā lapa pievienošanai =====
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({
    required this.presetCategory,
    this.presetDate,
    required this.isLV,
  });
  final TaskCategory presetCategory;
  final DateTime? presetDate;
  final bool isLV;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  TaskCategory _category = TaskCategory.darbs;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    _category = widget.presetCategory;
    _due = widget.presetDate;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String t(String lv, String en) => widget.isLV ? lv : en;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('Jauns uzdevums', 'New task'),
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: t('Nosaukums', 'Title'),
                hintText: t('Ko jādara?', 'What to do?'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t('Ievadi nosaukumu', 'Enter title') : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskCategory>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: t('Kategorija', 'Category'),
                      border: const OutlineInputBorder(),
                    ),
                    items: TaskCategory.values
                        .where((c) => c != TaskCategory.visi)
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text((widget.isLV ? kCategoryNameLV : kCategoryNameEN)[c]!),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: InputDecoration(
                      labelText: t('Prioritāte', 'Priority'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: TaskPriority.high,
                        child: Text(t('Augsta', 'High')),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.medium,
                        child: Text(t('Vidēja', 'Medium')),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.low,
                        child: Text(t('Zema', 'Low')),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.none,
                        child: Text(t('Nav', 'None')),
                      ),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(
                      _due == null
                          ? t('Termiņš nav', 'No due date')
                          : DateFormat('y.MM.dd (EEE)').format(_due!),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _due ?? now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                        locale: widget.isLV ? const Locale('lv') : const Locale('en'),
                      );
                      if (picked != null) setState(() => _due = picked);
                    },
                  ),
                ),
                if (_due != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: t('Noņemt termiņu', 'Clear date'),
                    onPressed: () => setState(() => _due = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(t('Pievienot uzdevumu', 'Add task')),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop(TaskItem(
                      title: _titleCtrl.text.trim(),
                      category: _category,
                      priority: _priority,
                      createdAt: DateTime.now(),
                      dueDate: _due,
                      completed: false,
                    ));
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('Atcelt', 'Cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
