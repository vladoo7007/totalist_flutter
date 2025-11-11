// Totalist: divas galvenās sadaļas – "Uzdevumi" un "Kalendārs".
// Funkcija: prioritāšu karodziņi, kārtošana (prioritāte→alfabēts / alfabēts),
// pabeigto saraksta akordeons, koplietoti notikumi ar kalendāru (punkti dienā),
// pievienošana no abām sadaļām, LV lokalizācija, kompaktie kategoriju “čipi”.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// ===== Modeļi un palīglīdzekļi =====

/// Uzdevuma prioritāte (vizuāli: sarkans (augsta), dzeltens (vidēja), zils (zema))
enum TaskPriority { high, medium, low, none }

/// Uzdevuma kategorija (čipi augšā)
enum TaskCategory { visi, darbs, personigs, labasDomas, dzimsanasDienas }

/// Uzdevuma ieraksts
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

// Krāsas karodziņiem
Color priorityColor(TaskPriority p, ColorScheme cs) {
  switch (p) {
    case TaskPriority.high:
      return Colors.red;
    case TaskPriority.medium:
      return Colors.amber;
    case TaskPriority.low:
      return Colors.blue;
    case TaskPriority.none:
      return cs.outline; // “bezkrāsas” kontūra, kad pabeigts
  }
}

// Latvisks nosaukums kategorijām
const Map<TaskCategory, String> kCategoryName = {
  TaskCategory.visi: 'Visi',
  TaskCategory.darbs: 'Darbs',
  TaskCategory.personigs: 'Personīgs',
  TaskCategory.labasDomas: 'Labas domas',
  TaskCategory.dzimsanasDienas: 'Dzimšanas dienas',
};

// ===== App starts =====

void main() {
  Intl.defaultLocale = 'lv_LV';
  runApp(const TotalistApp());
}

class TotalistApp extends StatelessWidget {
  const TotalistApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Bāzes tēma + Google Fonts
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF2563EB),
      brightness: Brightness.light,
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
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
        ),
      ),
      // Lokalizācijas atbalsts (latviešu UI)
      supportedLocales: const [Locale('lv')],
      locale: const Locale('lv'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

// ===== Home ar divām cilnēm: Uzdevumi un Kalendārs =====

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // LV: apakšējās navigācijas cilne (0=Uzdevumi, 1=Kalendārs)
  int _tab = 0;

  // LV: “Pabeigtie” akordeona stāvoklis
  bool _completedExpanded = false;

  // LV: kārtošanas režīms (true = prioritāte→alfabēts; false = alfabēts)
  bool _sortByPriorityThenAlpha = true;

  // LV: kategoriju joslas režīms (false = kompakts tikai ikonas; true = izvērsts ar tekstu)
  bool _chipsExpanded = false;

  // LV: atlasītā kategorija čipos (pēc noklusējuma Visi)
  TaskCategory _selectedCat = TaskCategory.visi;

  // LV: koplietots uzdevumu saraksts (viena patiesība visai app)
  final List<TaskItem> _items = [];

  // LV: kalendāra stāvoklis
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // ===== Kārtošana un filtrēšana =====
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
      // Augsta (0) -> vidēja (1) -> zema (2) -> none (3)
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
      } else {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });
  }

  // ===== Kalendāra event-loader (punkti dienās ar uzdevumiem) =====
  List<TaskItem> _eventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _items.where((t) {
      if (t.dueDate == null) return false;
      final x = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return x == d;
    }).toList();
  }

  // ===== Pievienošanas dialogi =====

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
        ),
      ),
    );

    if (result != null) {
      setState(() => _items.add(result));
    }
  }

  // Mainīt pabeigtības statusu
  void _toggleCompleted(TaskItem t) {
    setState(() => t.completed = !t.completed);
  }

  // Mainīt prioritāti
  void _setPriority(TaskItem t, TaskPriority p) {
    setState(() => t.priority = p);
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final pages = [
      _buildTasksPage(context, cs),
      _buildCalendarPage(context, cs),
    ];

    final titles = ['Totalist · Uzdevumi', 'Totalist · Kalendārs'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          if (_tab == 0) ...[
            // Kārtošanas slēdzis ar maināmu ikonu
            IconButton(
              tooltip: _sortByPriorityThenAlpha
                  ? 'Kārtošana: prioritātes → alfabēts'
                  : 'Kārtošana: alfabēts',
              onPressed: () => setState(
                () => _sortByPriorityThenAlpha = !_sortByPriorityThenAlpha,
              ),
              icon: Icon(
                _sortByPriorityThenAlpha
                    ? Icons.flag_outlined
                    : Icons.sort_by_alpha,
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
                  child: Text(
                    _completedExpanded
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
        ],
      ),
      body: pages[_tab],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tab == 0) {
            _openQuickAdd();
          } else {
            // Kalendārā – pievienot ar atlasītu dienu (ja nav atlasīta, izmanto fokusu)
            _openQuickAdd(presetDate: _selectedDay ?? _focusedDay);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Pievienot'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Uzdevumi'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Kalendārs',
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

  // LV: Kategoriju josla ar “kompakts/izvērsts” režīmu
  // - īss pieskāriens uz čipa = izvēlēties kategoriju
  // - ilgspiediens uz jebkura čipa = pārslēgt režīmu
  // - papildu ActionChip “Izvērst/Sakļaut”
  Widget _buildCategoryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final catList = <TaskCategory>[
      TaskCategory.visi,
      TaskCategory.darbs,
      TaskCategory.personigs,
      TaskCategory.labasDomas,
      TaskCategory.dzimsanasDienas,
    ];

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
          for (final cat in catList)
            GestureDetector(
              onLongPress: () =>
                  setState(() => _chipsExpanded = !_chipsExpanded),
              child: FilterChip(
                label: _chipsExpanded
                    ? Text(kCategoryName[cat]!)
                    : const Text(''),
                avatar: Icon(iconFor(cat)),
                showCheckmark: false,
                selected: _selectedCat == cat,
                onSelected: (_) => setState(() => _selectedCat = cat),
                side: BorderSide(
                  color: _selectedCat == cat ? cs.primary : cs.outlineVariant,
                ),
                // kompaktais “miglainais” efekts – mazāks kontrasts
                backgroundColor: _chipsExpanded
                    ? cs.surfaceContainer
                    : cs.surfaceContainerHigh,
                selectedColor: _chipsExpanded
                    ? cs.primaryContainer
                    : cs.primaryContainer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ActionChip(
            avatar: Icon(
              _chipsExpanded ? Icons.unfold_less : Icons.unfold_more,
            ),
            label: Text(_chipsExpanded ? 'Sakļaut' : 'Izvērst'),
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
          ...active.map(
            (t) => _TaskTile(
              item: t,
              onToggleDone: () => _toggleCompleted(t),
              onSetPriority: (p) => _setPriority(t, p),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Nav uzdevumu. Pievieno jaunu!')),
          ),
        const SizedBox(height: 16),
        ExpansionTile(
          initiallyExpanded: _completedExpanded,
          onExpansionChanged: (v) => setState(() => _completedExpanded = v),
          title: const Text('Pabeigtie'),
          children: completed.isEmpty
              ? const [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Šobrīd nav pabeigtu uzdevumu.'),
                  ),
                ]
              : completed
                    .map(
                      (t) => _TaskTile(
                        item: t,
                        onToggleDone: () => _toggleCompleted(t),
                        onSetPriority: (p) => _setPriority(t, p),
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }

  // ===== Kalendāra lapa =====
  Widget _buildCalendarPage(BuildContext context, ColorScheme cs) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TableCalendar<TaskItem>(
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
              // LV: bez šī formatButton metiens krita ar assert — tagad OK
              onFormatChanged: (f) => setState(() => _calendarFormat = f),
              calendarFormat: _calendarFormat,
              eventLoader: _eventsForDay,
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
              startingDayOfWeek: StartingDayOfWeek.monday,
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
            // Saraksts zem kalendāra – konkrētās dienas uzdevumi
            Expanded(
              child: Builder(
                builder: (ctx) {
                  final day = _selectedDay ?? _focusedDay;
                  final es = _eventsForDay(day);
                  if (es.isEmpty) {
                    return const Center(
                      child: Text('Šajā dienā nav uzdevumu.'),
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
                },
              ),
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
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
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
              // “Hamburger” ar prioritātēm
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
              // Checkbox
              Checkbox(value: item.completed, onChanged: (_) => onToggleDone()),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<TaskPriority> _prioItem(TaskPriority p, String title, Color c) {
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
  const _AddTaskSheet({required this.presetCategory, this.presetDate});

  final TaskCategory presetCategory;
  final DateTime? presetDate;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Virsraksts
            Text(
              'Jauns uzdevums',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // Nosaukums
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Nosaukums',
                hintText: 'Ko jādara?',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ievadi nosaukumu' : null,
            ),
            const SizedBox(height: 12),

            // Kategorija + prioritāte rindiņā
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskCategory>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategorija',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskCategory.values
                        .where((c) => c != TaskCategory.visi)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(kCategoryName[c]!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioritāte',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TaskPriority.high,
                        child: Text('Augsta'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.medium,
                        child: Text('Vidēja'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.low,
                        child: Text('Zema'),
                      ),
                      DropdownMenuItem(
                        value: TaskPriority.none,
                        child: Text('Nav'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Termiņa izvēle
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(
                      _due == null
                          ? 'Termiņš nav'
                          : DateFormat('y.MM.dd (EEE)').format(_due!),
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _due ?? now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                        locale: const Locale('lv'),
                      );
                      if (picked != null) {
                        setState(() => _due = picked);
                      }
                    },
                  ),
                ),
                if (_due != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Noņemt termiņu',
                    onPressed: () => setState(() => _due = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Poga saglabāt
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Pievienot uzdevumu'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop(
                      TaskItem(
                        title: _titleCtrl.text.trim(),
                        category: _category,
                        priority: _priority,
                        createdAt: DateTime.now(),
                        dueDate: _due,
                        completed: false,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Atcelt'),
            ),
          ],
        ),
      ),
    );
  }
}
