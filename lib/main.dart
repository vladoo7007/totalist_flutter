import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Иниц. локалей, иначе был ваш LocaleDataException
  await initializeDateFormatting('lv');
  Intl.defaultLocale = 'lv';
  runApp(const TotalistApp());
}

/* ============================== МОДЕЛИ ============================== */

enum TaskCategory { all, work, personal, ideas, birthdays }

enum TaskPriority { none, low, medium, high }

class TaskItem {
  TaskItem({
    required this.title,
    required this.category,
    this.priority = TaskPriority.none,
    this.completed = false,
    this.date, // если есть — задача видна на календаре
  });

  String title;
  TaskCategory category;
  TaskPriority priority;
  bool completed;
  DateTime? date;
}

/* ============================== ПРИЛОЖЕНИЕ ============================== */

class TotalistApp extends StatelessWidget {
  const TotalistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF6D64C3),
      brightness: Brightness.light,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Totalist',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
        appBarTheme: base.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: base.colorScheme.onSurface,
          ),
          elevation: 0,
        ),
      ),
      supportedLocales: const [Locale('lv'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}

/* ============================== ОБОЛОЧКА (2 вкладки) ============================== */

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  // Ключ для связи FAB и списка задач
  final GlobalKey<TasksPageState> _tasksKey = GlobalKey<TasksPageState>();
  // Ключ календаря — чтобы передать выбранную дату в быстрый ввод
  final GlobalKey<CalendarPageState> _calendarKey = GlobalKey<CalendarPageState>();

  @override
  Widget build(BuildContext context) {
    final page = _tabIndex == 0
        ? TasksPage(key: _tasksKey)
        : CalendarPage(key: _calendarKey, getTasksForDay: _getTasksForDay);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabIndex == 0 ? 'Totalist · Uzdevumi' : 'Totalist · Kalendārs'),
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _tasksKey.currentState?.openQuickAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Pievienot'),
            )
          : Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  final selected = _calendarKey.currentState?.selectedDay;
                  _tasksKey.currentState?.openQuickAdd(context, presetDate: selected);
                },
                icon: const Icon(Icons.add),
                label: const Text('Pievienot šai dienai'),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.tune), label: 'Uzdevumi'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Kalendārs'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: page,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
    );
  }

  /// Простой провайдер задач к календарю
  List<TaskItem> _getTasksForDay(DateTime day) {
    final tasks = _tasksKey.currentState?.items ?? const <TaskItem>[];
    return tasks.where((t) {
      if (t.date == null) return false;
      final d = DateUtils.dateOnly(t.date!);
      return d == DateUtils.dateOnly(day);
    }).toList(growable: false);
  }
}

/* ============================== СТРАНИЦА ЗАДАЧ ============================== */

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => TasksPageState();
}

class TasksPageState extends State<TasksPage> {
  // Состояния
  final List<TaskItem> _items = <TaskItem>[];
  TaskCategory _selectedCat = TaskCategory.all;
  bool _sortByPriorityThenAlpha = true;
  bool _completedExpanded = false;

  UnmodifiableListView<TaskItem> get items => UnmodifiableListView(_items);

  /* ---------- ПУБЛИЧНЫЕ МЕТОДЫ ДЛЯ FAB ---------- */
  Future<void> openQuickAdd(BuildContext ctx, {DateTime? presetDate}) async {
    final cs = Theme.of(ctx).colorScheme;
    String? text;
    TaskCategory cat = _selectedCat == TaskCategory.all ? TaskCategory.personal : _selectedCat;
    TaskPriority pri = TaskPriority.none;
    DateTime? pickedDate = presetDate;

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              TextFormField(
                autofocus: true,
                initialValue: '',
                onChanged: (v) => text = v.trim(),
                decoration: const InputDecoration(
                  labelText: 'Ierakstiet jaunu uzdevumu šeit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _CategoryPicker(
                      initial: cat,
                      onChanged: (v) => cat = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PriorityPicker(
                      initial: pri,
                      onChanged: (v) => pri = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final init = pickedDate ?? now;
                        // простой date picker для Web/desktop
                        final result = await showDatePicker(
                          context: sheetCtx,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 3),
                          initialDate: init,
                          locale: const Locale('lv'),
                        );
                        if (result != null) {
                          pickedDate = result;
                          // визуально подтверждать не будем — достаточно кнопки
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        pickedDate == null
                            ? 'Bez datuma'
                            : DateFormat.yMMMMd('lv').format(pickedDate!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if ((text ?? '').isEmpty) {
                          Navigator.pop(sheetCtx);
                          return;
                        }
                        setState(() {
                          _items.add(TaskItem(
                            title: text!,
                            category: cat,
                            priority: pri,
                            date: pickedDate,
                          ));
                        });
                        Navigator.pop(sheetCtx);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Pievienot'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text('Atcelt'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /* ------------------ BUILD ------------------ */

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // AppBar уже в оболочке — здесь только Actions (правый верх)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _buildCategoryChips(context),
          const SizedBox(height: 16),
          Expanded(child: _buildTaskLists(context)),
        ],
      ),
      backgroundColor: cs.surface.withValues(alpha: 0.98),
      // Actions AppBar (справа) — через Align вверху
      // но удобнее перенести прямо в оболочку — оставим тут Popup по макету:
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final labels = {
      TaskCategory.all: 'Visi',
      TaskCategory.work: 'Darbs',
      TaskCategory.personal: 'Personīgs',
      TaskCategory.ideas: 'Labas domas',
      TaskCategory.birthdays: 'Dzimšanas dienas',
    };

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskCategory.values.map((cat) {
                final selected = _selectedCat == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[cat]!),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCat = cat),
                    shape: StadiumBorder(side: BorderSide(color: cs.outlineVariant)),
                    selectedColor: cs.primary.withValues(alpha: 0.10),
                    labelStyle: TextStyle(
                      color: selected ? cs.primary : cs.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Кнопка сортировки
        IconButton(
          tooltip: _sortByPriorityThenAlpha
              ? 'Kārtošana: prioritātes → alfabēts'
              : 'Kārtošana: alfabēts',
          onPressed: () => setState(() => _sortByPriorityThenAlpha = !_sortByPriorityThenAlpha),
          icon: Icon(_sortByPriorityThenAlpha ? Icons.flag_outlined : Icons.sort_by_alpha),
        ),
        // Меню
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
              child: Text(_completedExpanded ? 'Slēgt “Pabeigtie”' : 'Atvērt “Pabeigtie”'),
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

  Widget _buildTaskLists(BuildContext context) {
    // Фильтруем по категории
    Iterable<TaskItem> data = _items.where((t) {
      if (_selectedCat == TaskCategory.all) return true;
      return t.category == _selectedCat;
    });

    // Сортировка
    int priScore(TaskPriority p) {
      switch (p) {
        case TaskPriority.high:
          return 3;
        case TaskPriority.medium:
          return 2;
        case TaskPriority.low:
          return 1;
        case TaskPriority.none:
          return 0;
      }
    }

    final active = data.where((t) => !t.completed).toList();
    final done = data.where((t) => t.completed).toList();

    if (_sortByPriorityThenAlpha) {
      active.sort((a, b) {
        final byPri = priScore(b.priority).compareTo(priScore(a.priority));
        if (byPri != 0) return byPri;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else {
      active.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    // выполненные всегда в алфавите
    done.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return ListView(
      children: [
        ...active.map((t) => _TaskTile(
              item: t,
              onToggle: (v) => setState(() => t.completed = v),
              onSetPriority: (p) => setState(() => t.priority = p),
            )),
        const SizedBox(height: 12),
        ExpansionTile(
          initiallyExpanded: _completedExpanded,
          onExpansionChanged: (v) => setState(() => _completedExpanded = v),
          title: const Text('Pabeigtie'),
          children: done
              .map((t) => _TaskTile(
                    item: t,
                    onToggle: (v) => setState(() => t.completed = v),
                    onSetPriority: (p) => setState(() => t.priority = p),
                  ))
              .toList(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

/* ============================== ТАЙЛ ЗАДАЧИ ============================== */

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.item,
    required this.onToggle,
    required this.onSetPriority,
  });

  final TaskItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<TaskPriority> onSetPriority;

  Color? _flagColor(TaskPriority p, ColorScheme cs) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.amber[700];
      case TaskPriority.low:
        return Colors.indigo;
      case TaskPriority.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final flag = _flagColor(item.priority, cs);

    final titleStyle = item.completed
        ? TextStyle(
            decoration: TextDecoration.lineThrough,
            color: cs.onSurface.withValues(alpha: 0.4),
          )
        : TextStyle(color: cs.onSurface);

    final subtitle = _categoryLabel(item.category) +
        (item.date != null ? ' • ${DateFormat.yMMMd('lv').format(item.date!)}' : '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: item.completed,
          onChanged: (v) => onToggle(v ?? false),
        ),
        title: Text(item.title, style: titleStyle),
        subtitle: Text(
          subtitle,
          style:
              TextStyle(color: cs.onSurfaceVariant.withValues(alpha: item.completed ? 0.4 : 1)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // цветной флажок (или бесцветный, если выполнено)
            Icon(
              Icons.flag,
              size: 18,
              color: item.completed ? cs.outlineVariant : (flag ?? cs.outlineVariant),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<TaskPriority>(
              icon: const Icon(Icons.drag_handle),
              tooltip: 'Iestatīt prioritāti',
              onSelected: onSetPriority,
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: TaskPriority.high, child: _PriorityMenuRow('Sarkans (augsta)')),
                PopupMenuItem(value: TaskPriority.medium, child: _PriorityMenuRow('Dzeltens (vidēja)')),
                PopupMenuItem(value: TaskPriority.low, child: _PriorityMenuRow('Zils (zema)')),
                PopupMenuDivider(),
                PopupMenuItem(value: TaskPriority.none, child: Text('Bez prioritātes')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(TaskCategory c) {
    switch (c) {
      case TaskCategory.all:
        return 'Visi';
      case TaskCategory.work:
        return 'Darbs';
      case TaskCategory.personal:
        return 'Personīgs';
      case TaskCategory.ideas:
        return 'Labas domas';
      case TaskCategory.birthdays:
        return 'Dzimšanas dienas';
    }
  }
}

class _PriorityMenuRow extends StatelessWidget {
  const _PriorityMenuRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text);
}

/* ============================== КАЛЕНДАРЬ ============================== */

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.getTasksForDay});

  final List<TaskItem> Function(DateTime day) getTasksForDay;

  @override
  State<CalendarPage> createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateUtils.dateOnly(DateTime.now());
  DateTime _selectedDay = DateUtils.dateOnly(DateTime.now());

  DateTime get selectedDay => _selectedDay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Kalendārs', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TableCalendar<TaskItem>(
          locale: 'lv',
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => DateUtils.isSameDay(d, _selectedDay),
          startingDayOfWeek: StartingDayOfWeek.monday,
          eventLoader: (day) => widget.getTasksForDay(day),
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              border: Border.all(color: cs.primary),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = DateUtils.dateOnly(selected);
              _focusedDay = focused;
            });
          },
        ),
        const SizedBox(height: 12),
        Text('Šīs dienas uzdevumi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: _DayTasksList(items: widget.getTasksForDay(_selectedDay)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DayTasksList extends StatelessWidget {
  const _DayTasksList({required this.items});
  final List<TaskItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Šajā dienā nav uzdevumu.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final t = items[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.task_alt),
          title: Text(t.title),
          subtitle: Text(_cat(t.category)),
        );
      },
    );
  }

  String _cat(TaskCategory c) {
    switch (c) {
      case TaskCategory.all:
        return 'Visi';
      case TaskCategory.work:
        return 'Darbs';
      case TaskCategory.personal:
        return 'Personīgs';
      case TaskCategory.ideas:
        return 'Labas domas';
      case TaskCategory.birthdays:
        return 'Dzimšanas dienas';
    }
  }
}

/* ============================== ПИКЕРЫ ============================== */

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({required this.initial, required this.onChanged});
  final TaskCategory initial;
  final ValueChanged<TaskCategory> onChanged;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  late TaskCategory _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskCategory>(
      value: _value,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _value = v);
        widget.onChanged(v);
      },
      decoration: const InputDecoration(labelText: 'Kategorija', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: TaskCategory.work, child: Text('Darbs')),
        DropdownMenuItem(value: TaskCategory.personal, child: Text('Personīgs')),
        DropdownMenuItem(value: TaskCategory.ideas, child: Text('Labas domas')),
        DropdownMenuItem(value: TaskCategory.birthdays, child: Text('Dzimšanas dienas')),
      ],
    );
  }
}

class _PriorityPicker extends StatefulWidget {
  const _PriorityPicker({required this.initial, required this.onChanged});
  final TaskPriority initial;
  final ValueChanged<TaskPriority> onChanged;

  @override
  State<_PriorityPicker> createState() => _PriorityPickerState();
}

class _PriorityPickerState extends State<_PriorityPicker> {
  late TaskPriority _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskPriority>(
      value: _value,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _value = v);
        widget.onChanged(v);
      },
      decoration: const InputDecoration(labelText: 'Prioritāte', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: TaskPriority.high, child: Text('Sarkans (augsta)')),
        DropdownMenuItem(value: TaskPriority.medium, child: Text('Dzeltens (vidēja)')),
        DropdownMenuItem(value: TaskPriority.low, child: Text('Zils (zema)')),
        DropdownMenuItem(value: TaskPriority.none, child: Text('Bez prioritātes')),
      ],
    );
  }
}
