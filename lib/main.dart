// ======================
// Totalist — galvenais fails
// Visi komentāri latviski, UI teksts arī latviski
// ======================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

// ----------------------
// Datu modelis
// ----------------------
enum TaskPriority {
  none,   // bez prioritātes
  low,    // zils (mazsvarīgs)
  medium, // dzeltens (vidējs)
  high,   // sarkans (ļoti svarīgs)
}

class TaskItem {
  TaskItem({
    required this.title,
    required this.category,
    this.priority = TaskPriority.none,
    this.completed = false,
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String title;                 // uzdevuma nosaukums
  String category;              // Visi / Darbs / Personīgs / Labas domas / Dzimšanas dienas
  TaskPriority priority;        // prioritāte (flagi)
  bool completed;               // vai pabeigts
  DateTime? dueDate;            // saistīt ar kalendāru
  final DateTime createdAt;     // izveides datums
}

// ----------------------
// Galvenā lietotne
// ----------------------
void main() {
  runApp(const TotalistApp());
}

class TotalistApp extends StatelessWidget {
  const TotalistApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bāzes tēma + Google Fonts
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E77FF),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Totalist',
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
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Lokalizācijas deleģenti (iekļauj lv)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('lv'), // latviešu
        Locale('en'), // rezerves
      ],

      home: const HomeShell(),
    );
  }
}

// ----------------------
// Galvenais rāmis ar 2 cilnēm: Uzdevumi + Kalendārs
// ----------------------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late final TabController _tab;
  final GlobalKey<_TasksPageState> _tasksKey = GlobalKey<_TasksPageState>();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Teksta virsraksts atkarībā no cilnes
  String get _title => _tab.index == 0 ? 'Totalist · Uzdevumi' : 'Totalist · Kalendārs';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.checklist), text: 'Uzdevumi'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Kalendārs'),
          ],
        ),
        actions: [
          // Šeit rādām tikai Uzdevumu lapai paredzētās darbības
          if (_tab.index == 0)
            _TasksActions(tasksKey: _tasksKey),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          TasksPage(key: _tasksKey),
          CalendarPage(tasksKey: _tasksKey),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _tasksKey.currentState?._openQuickAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Pievienot'),
            )
          : null,
      backgroundColor: cs.surface.withValues(alpha: 0.98),
    );
  }
}

// ----------------------
// Augšējās darbības (sort ikona + popup izvēlne)
// ----------------------
class _TasksActions extends StatelessWidget {
  const _TasksActions({required this.tasksKey});

  final GlobalKey<_TasksPageState> tasksKey;

  @override
  Widget build(BuildContext context) {
    final st = tasksKey.currentState;

    return Row(
      children: [
        // Sākumā — kārtošanas poga (ikona mainās!)
        IconButton(
          tooltip: st?._sortByPriorityThenAlpha == true
              ? 'Kārtošana: prioritātes → alfabēts'
              : 'Kārtošana: alfabēts',
          onPressed: () => st?.toggleSort(),
          icon: Icon(
            st?._sortByPriorityThenAlpha == true
                ? Icons.flag_outlined
                : Icons.sort_by_alpha,
          ),
        ),

        // Trīs punktu izvēlne
        PopupMenuButton<String>(
          onSelected: (value) => st?._onMenu(value),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'toggle_completed',
              child: Text(
                (st?._completedExpanded ?? true)
                    ? 'Slēgt “Pabeigtie”'
                    : 'Atvērt “Pabeigtie”',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'clear_completed',
              child: Text('Iztīrīt pabeigtos'),
            ),
          ],
        ),
      ],
    );
  }
}

// ----------------------
// Uzdevumu lapa
// ----------------------
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // Stāvoklis
  bool _sortByPriorityThenAlpha = true; // Kārtošanas režīms
  bool _completedExpanded = false;      // Pabeigto sekcijas stāvoklis
  int _selectedCat = 0;                 // 0..4
  final categories = const [
    'Visi', 'Darbs', 'Personīgs', 'Labas domas', 'Dzimšanas dienas'
  ];

  final TextEditingController _addCtrl = TextEditingController();

  // Uzdevumu saraksts (vienkāršs atmiņā)
  final List<TaskItem> _items = [
    TaskItem(title: 'Piezvanīt klientam', category: 'Darbs', priority: TaskPriority.high),
    TaskItem(title: 'Treniņš', category: 'Personīgs', priority: TaskPriority.medium),
    TaskItem(title: 'Apsveikt Juri', category: 'Dzimšanas dienas', priority: TaskPriority.low, dueDate: DateTime.now()),
    TaskItem(title: 'Pateicības pieraksts', category: 'Labas domas'),
  ];

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  // ---------- Palīgfunkcijas ----------

  // Kārto pēc režīma
  int _cmp(TaskItem a, TaskItem b) {
    if (_sortByPriorityThenAlpha) {
      // prioritāte (augstāk uz augšu) → alfabēts
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    } else {
      // tikai alfabēts
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  }

  // Atlasīt redzamos (pēc kategorijas)
  Iterable<TaskItem> _visibleNotCompleted() {
    final currentCat = categories[_selectedCat];
    return _items.where((t) {
      final inCat = currentCat == 'Visi' || t.category == currentCat;
      return inCat && !t.completed;
    }).toList()
      ..sort(_cmp);
  }

  Iterable<TaskItem> _visibleCompleted() {
    final currentCat = categories[_selectedCat];
    return _items.where((t) {
      final inCat = currentCat == 'Visi' || t.category == currentCat;
      return inCat && t.completed;
    }).toList()
      ..sort(_cmp);
  }

  // Publiskas darbības no AppBar
  void toggleSort() => setState(() => _sortByPriorityThenAlpha = !_sortByPriorityThenAlpha);

  void _onMenu(String value) {
    switch (value) {
      case 'toggle_completed':
        setState(() => _completedExpanded = !_completedExpanded);
      case 'clear_completed':
        setState(() => _items.removeWhere((t) => t.completed));
    }
  }

  // Ātra pievienošana (FAB)
  Future<void> _openQuickAdd(BuildContext context) async {
    String cat = categories[_selectedCat];
    TaskPriority pr = TaskPriority.none;
    DateTime? due;

    _addCtrl.clear();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Jauns uzdevums'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nosaukums',
                ),
                autofocus: true,
                onSubmitted: (_) => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 12),
              // Kategorija
              DropdownButtonFormField<String>(
                value: cat,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => cat = v ?? cat,
                decoration: const InputDecoration(labelText: 'Kategorija'),
              ),
              const SizedBox(height: 12),
              // Prioritāte
              DropdownButtonFormField<TaskPriority>(
                value: pr,
                items: TaskPriority.values.map((p) {
                  final name = switch (p) {
                    TaskPriority.high => 'Sarkans (ļoti svarīgs)',
                    TaskPriority.medium => 'Dzeltens (vidējs)',
                    TaskPriority.low => 'Zils (mazsvarīgs)',
                    TaskPriority.none => 'Bez prioritātes',
                  };
                  return DropdownMenuItem(value: p, child: Text(name));
                }).toList(),
                onChanged: (v) => pr = v ?? pr,
                decoration: const InputDecoration(labelText: 'Prioritāte'),
              ),
              const SizedBox(height: 12),
              // Datums
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(due == null ? 'Bez datuma' : _fmtDate(due)),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 5),
                          initialDate: due ?? now,
                          locale: const Locale('lv'),
                        );
                        if (picked != null) {
                          due = DateTime(picked.year, picked.month, picked.day);
                          // atjauninām dialogu
                          (ctx as Element).markNeedsBuild();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Atcelt'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            FilledButton(
              child: const Text('Pievienot'),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    ).then((ok) {
      if (ok == true && _addCtrl.text.trim().isNotEmpty) {
        setState(() {
          _items.add(TaskItem(
            title: _addCtrl.text.trim(),
            category: cat,
            priority: pr,
            dueDate: due,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uzdevums pievienots')),
        );
      }
    });
  }

  // Prioritātes ikona (hamburger -> izvēlne ar flagiem)
  void _changePriority(BuildContext context, TaskItem t) async {
    final picked = await showMenu<TaskPriority>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 200, 0, 0),
      items: [
        PopupMenuItem(value: TaskPriority.high, child: _prioRow(Icons.flag, Colors.red, 'Sarkans (ļoti svarīgs)')),
        PopupMenuItem(value: TaskPriority.medium, child: _prioRow(Icons.flag, Colors.amber, 'Dzeltens (vidējs)')),
        PopupMenuItem(value: TaskPriority.low, child: _prioRow(Icons.flag, Colors.blue, 'Zils (mazsvarīgs)')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: TaskPriority.none, child: Text('Noņemt prioritāti')),
      ],
    );
    if (picked != null) setState(() => t.priority = picked);
  }

  Widget _prioRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  // Čipu josla (kategorijas)
  Widget _buildCategoryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final selected = _selectedCat == i;
          return ChoiceChip(
            selected: selected,
            label: Text(categories[i]),
            onSelected: (_) => setState(() => _selectedCat = i),
            selectedColor: cs.primary.withValues(alpha: 0.15),
            side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
          );
        },
      ),
    );
  }

  // Uzdevumu saraksti (aktīvie + pabeigtie kā akordeons)
  Widget _buildTaskLists(BuildContext context) {
    final active = _visibleNotCompleted().toList();
    final done = _visibleCompleted().toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Aktīvie
          ...active.map((t) => _TaskTile(
                item: t,
                onToggleDone: (v) => setState(() => t.completed = v),
                onPriorityTap: () => _changePriority(context, t),
              )),
          const SizedBox(height: 8),

          // Pabeigtie (ExpansionTile ar kontrolētu stāvokli)
          if (done.isNotEmpty)
            ExpansionTile(
              key: ValueKey(_completedExpanded), // lai pārbūvētos pie slēgšanas/atvēršanas no izvēlnes
              initiallyExpanded: _completedExpanded,
              onExpansionChanged: (v) => setState(() => _completedExpanded = v),
              title: const Text('Pabeigtie'),
              children: [
                const Divider(height: 1),
                ...done.map((t) => _TaskTile(
                      item: t,
                      dimCompleted: true,
                      onToggleDone: (v) => setState(() => t.completed = v),
                      onPriorityTap: () => _changePriority(context, t),
                    )),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }

  // Galvenais build
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildCategoryChips(context),
            const SizedBox(height: 16),
            Expanded(child: _buildTaskLists(context)),
          ],
        ),
      ),
    );
  }
}

// Viena uzdevuma flīze
class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.item,
    required this.onToggleDone,
    required this.onPriorityTap,
    this.dimCompleted = false,
  });

  final TaskItem item;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onPriorityTap;
  final bool dimCompleted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color? prioColor = switch (item.priority) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.amber,
      TaskPriority.low => Colors.blue,
      TaskPriority.none => null,
    };

    final style = TextStyle(
      decoration: item.completed ? TextDecoration.lineThrough : null,
      color: item.completed ? cs.onSurface.withValues(alpha: 0.4) : null,
      fontWeight: FontWeight.w600,
    );

    return Card(
      elevation: 0,
      color: dimCompleted ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: false,
        leading: Checkbox(
          value: item.completed,
          onChanged: (v) => onToggleDone(v ?? false),
        ),
        title: Text(item.title, style: style),
        subtitle: Row(
          children: [
            if (item.dueDate != null) ...[
              const Icon(Icons.event, size: 14),
              const SizedBox(width: 4),
              Text(_fmtDate(item.dueDate)),
              const SizedBox(width: 12),
            ],
            Text(item.category),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mazs “flaģis” (krāsa bez teksta) — tikai, ja ir prioritāte
            if (prioColor != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.flag, size: 18, color: prioColor),
              ),
            // “Hamburgera” izvēlne: mainīt prioritāti
            IconButton(
              tooltip: 'Prioritāte',
              icon: const Icon(Icons.more_vert),
              onPressed: onPriorityTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------
// Kalendāra lapa
// ----------------------
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.tasksKey});

  final GlobalKey<_TasksPageState> tasksKey;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  // Notikumi no otra skata (visi uzdevumi ar dueDate)
  Map<DateTime, List<TaskItem>> get _events {
    final items = widget.tasksKey.currentState?._items ?? const <TaskItem>[];
    final map = <DateTime, List<TaskItem>>{};
    for (final t in items) {
      if (t.dueDate == null) continue;
      final day = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      map.putIfAbsent(day, () => []).add(t);
    }
    return map;
  }

  List<TaskItem> _getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _events[d] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final eventsToday = _getEventsForDay(_selected ?? DateTime.now());

    return Column(
      children: [
        TableCalendar<TaskItem>(
          locale: 'lv',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(d, _selected),
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: cs.secondary,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (sel, foc) {
            setState(() {
              _selected = sel;
              _focused = foc;
            });
          },
          onPageChanged: (foc) => _focused = foc,
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: eventsToday.length,
            itemBuilder: (ctx, i) {
              final t = eventsToday[i];
              final color = switch (t.priority) {
                TaskPriority.high => Colors.red,
                TaskPriority.medium => Colors.amber,
                TaskPriority.low => Colors.blue,
                TaskPriority.none => Colors.grey,
              };
              return ListTile(
                leading: Icon(Icons.flag, color: color),
                title: Text(t.title),
                subtitle: Text(t.category),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------
// Palīgs
// ----------------------
String _fmtDate(DateTime? d) {
  if (d == null) return '';
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd.$mm.$yyyy';
}
