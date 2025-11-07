import 'package:flutter/material.dart';

void main() => runApp(const TotalistApp());

/// Totalist — ToDo skelets (UI latviski, komentāri latviski)
class TotalistApp extends StatelessWidget {
  const TotalistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Totalist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C6BD6)),
      ),
      home: const HomeShell(),
    );
  }
}

/// Apakšējā navigācija (Uzdevumi/Kalendārs) + FAB no šejienes
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  // Atslēga, lai sazinātos ar Uzdevumu lapu
  final GlobalKey<_TasksPageState> _tasksKey = GlobalKey<_TasksPageState>();

  @override
  Widget build(BuildContext context) {
    final page = switch (_tabIndex) {
      0 => TasksPage(key: _tasksKey),
      _ => const CalendarPage(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabIndex == 0 ? 'Totalist · Uzdevumi' : 'Totalist · Kalendārs',
        ),
        scrolledUnderElevation: 0,
      ),
      // Peldošā poga redzama tikai Uzdevumu cilnē
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _tasksKey.currentState?.openQuickAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('Pievienot'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.tune), label: 'Uzdevumi'),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Kalendārs',
          ),
        ],
      ),
    );
  }
}

/// ===== Datu modeļi =====
enum TaskCategory { work, personal, ideas, birthdays }

String categoryLabel(TaskCategory c) => switch (c) {
  TaskCategory.work => 'Darbs',
  TaskCategory.personal => 'Personīgs',
  TaskCategory.ideas => 'Labas domas',
  TaskCategory.birthdays => 'Dzimšanas dienas',
};

enum TaskPriority { high, medium, low, none }

class TaskItem {
  TaskItem({
    required this.title,
    required this.category,
    this.priority = TaskPriority.none,
    this.completed = false,
  });

  String title;
  TaskCategory category;
  TaskPriority priority;
  bool completed;
}

/// Uzdevumu lapa: filtri, kārtošana, prioritātes, “Pabeigtie” akordeons
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // Filtru saraksts (null = Visi)
  final List<TaskCategory?> _categories = const [
    null,
    TaskCategory.work,
    TaskCategory.personal,
    TaskCategory.ideas,
    TaskCategory.birthdays,
  ];
  int _selectedCat = 0;

  final List<TaskItem> _items = [];

  // true = prioritātes → alfabēts; false = alfabēts
  bool _sortByPriorityThenAlpha = true;

  bool _completedExpanded = false;

  /// Atver modāli un pievieno uzdevumu (ŠEIT ir viss “add”!)
  Future<void> openQuickAdd(BuildContext ctx) async {
    String text = '';
    TaskCategory cat = TaskCategory.personal;

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        final cs = Theme.of(sheetCtx).colorScheme;
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              TextField(
                autofocus: true,
                onChanged: (v) => text = v.trim(),
                decoration: const InputDecoration(
                  labelText: 'Ierakstiet jaunu uzdevumu šeit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Kategorija:'),
                  const SizedBox(width: 12),
                  DropdownButton<TaskCategory>(
                    value: cat,
                    onChanged: (v) => cat = v ?? cat,
                    items: TaskCategory.values
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(categoryLabel(c)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      if (text.isNotEmpty) {
                        setState(() {
                          _items.add(TaskItem(title: text, category: cat));
                        });
                      }
                      Navigator.pop(sheetCtx);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Pievienot'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close),
                    label: const Text('Atcelt'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Totalist · Uzdevumi'),
        actions: [
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
      ),
      body: SafeArea(
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
      ),
      backgroundColor: cs.surface.withValues(alpha: 0.98),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (i) {
          final selected = _selectedCat == i;
          final label = switch (_categories[i]) {
            null => 'Visi',
            TaskCategory.work => 'Darbs',
            TaskCategory.personal => 'Personīgs',
            TaskCategory.ideas => 'Labas domas',
            TaskCategory.birthdays => 'Dzimšanas dienas',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCat = i),
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
        }),
      ),
    );
  }

  Widget _buildTaskLists(BuildContext context) {
    final filtered = _filteredOpenItems();
    final completed = _filteredCompletedItems();

    return ListView(
      children: [
        if (filtered.isEmpty) _emptyState(context),
        ...filtered.map(
          (t) => _TaskTile(
            item: t,
            onChanged: (done) => setState(() => t.completed = done),
            onPriorityChanged: (p) => setState(() => t.priority = p),
            onDelete: () => setState(() => _items.remove(t)),
          ),
        ),
        if (completed.isNotEmpty) const SizedBox(height: 12),
        if (completed.isNotEmpty)
          _CompletedAccordion(
            count: completed.length,
            expanded: _completedExpanded,
            onToggle: () =>
                setState(() => _completedExpanded = !_completedExpanded),
            children: completed
                .map(
                  (t) => _TaskTile(
                    item: t,
                    onChanged: (done) => setState(() => t.completed = done),
                    onPriorityChanged: (p) => setState(() => t.priority = p),
                    onDelete: () => setState(() => _items.remove(t)),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 64, bottom: 24),
      child: Column(
        children: [
          Icon(
            Icons.event_note,
            size: 96,
            color: cs.outline.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          const Text(
            'Šajā kategorijā vēl nav uzdevumu.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('Nospiest “Pievienot”, lai izveidotu pirmo uzdevumu.'),
        ],
      ),
    );
  }

  List<TaskItem> _filteredOpenItems() {
    final cat = _categories[_selectedCat];
    final list = _items
        .where((t) => !t.completed && (cat == null || t.category == cat))
        .toList();

    if (_sortByPriorityThenAlpha) {
      list.sort((a, b) {
        final pr = b.priority.index.compareTo(
          a.priority.index,
        ); // augstāka vispirms
        if (pr != 0) return pr;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else {
      list.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return list;
  }

  List<TaskItem> _filteredCompletedItems() {
    final cat = _categories[_selectedCat];
    final list = _items
        .where((t) => t.completed && (cat == null || t.category == cat))
        .toList();
    list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }
}

class _CompletedAccordion extends StatelessWidget {
  const _CompletedAccordion({
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      child: ExpansionTile(
        onExpansionChanged: (_) => onToggle(),
        initiallyExpanded: expanded,
        title: Text('Pabeigtie ($count)'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.item,
    required this.onChanged,
    required this.onPriorityChanged,
    required this.onDelete,
  });

  final TaskItem item;
  final ValueChanged<bool> onChanged;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Checkbox(
          value: item.completed,
          onChanged: (v) => onChanged(v ?? false),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.completed ? TextDecoration.lineThrough : null,
            color: item.completed ? cs.onSurfaceVariant : cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          categoryLabel(item.category),
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag,
              size: 18,
              color: _priorityColor(
                cs,
                item.priority,
              ).withValues(alpha: item.completed ? 0.35 : 1.0),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.drag_handle_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'p_high':
                    onPriorityChanged(TaskPriority.high);
                    break;
                  case 'p_med':
                    onPriorityChanged(TaskPriority.medium);
                    break;
                  case 'p_low':
                    onPriorityChanged(TaskPriority.low);
                    break;
                  case 'edit':
                    _editTitle(context);
                    break;
                  case 'del':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'p_high',
                  child: Row(
                    children: const [
                      Icon(Icons.flag, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sarkanā (augsta)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'p_med',
                  child: Row(
                    children: const [
                      Icon(Icons.flag, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Dzeltenā (vidēja)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'p_low',
                  child: Row(
                    children: const [
                      Icon(Icons.flag, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Zilā (zema)'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Labot nosaukumu'),
                ),
                const PopupMenuItem(value: 'del', child: Text('Dzēst')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(ColorScheme cs, TaskPriority p) {
    return switch (p) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.blue,
      TaskPriority.none => cs.outline,
    };
  }

  Future<void> _editTitle(BuildContext context) async {
    var newTitle = item.title;
    await showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Labot uzdevumu'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: item.title),
          onChanged: (v) => newTitle = v.trim(),
          decoration: const InputDecoration(
            labelText: 'Nosaukums',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Atcelt'),
          ),
          FilledButton(
            onPressed: () {
              if (newTitle.isNotEmpty) item.title = newTitle;
              Navigator.pop(dCtx);
            },
            child: const Text('Saglabāt'),
          ),
        ],
      ),
    );
  }
}

/// Vienkāršs kalendāra placeholder
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'Kalendārs — drīzumā :)',
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
