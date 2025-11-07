import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() => runApp(const TotalistApp());

class TotalistApp extends StatelessWidget {
  const TotalistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Totalist',
      // ✅ Piespiežam latviešu lokalizāciju visai lietotnei
      locale: const Locale('lv'),
      supportedLocales: const [Locale('lv'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6E8BFF)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TasksPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // ✅ Kategoriju nosaukumi (UI skati filtrēšanai)
  final List<String> _categories = ['Visi', 'Darbs', 'Personīgi', 'Vēlmju saraksts', 'Dzimšanas dienas.'];
  int _selectedCat = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // ✅ Lietotnes virsraksts
        title: const Text('Totalist'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Horizontāli “čipi” kategoriju pārslēgšanai
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final selected = _selectedCat == i;
                  return ChoiceChip(
                    label: Text(_categories[i]),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCat = i),
                    selectedColor: cs.primary.withOpacity(.15),
                    labelStyle: TextStyle(
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ✅ Pagaidu “tukša stāvokļa” ekrāns (pirms uzdevumu saraksta)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Pagaidu ikona ilustrācijas vietā
                      Icon(Icons.event_note_rounded,
                          size: 120, color: cs.primary.withOpacity(.25)),
                      const SizedBox(height: 16),
                      Text(
                        'Šajā kategorijā vēl nav uzdevumu.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nospiediet +, lai izveidotu pirmo uzdevumu.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ✅ Peldošā poga “+” ātrai pievienošanai
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Pievienot'),
      ),

      // ✅ Apakšējā navigācija — pagaidām dekoratīva (nākamajiem soļiem)
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1, // “Uzdevumi”
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu), label: 'Lente'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Uzdevumi'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Kalendārs'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Mans'),
        ],
      ),
    );
  }

  // ✅ Ātrās pievienošanas apakšējais panelis (bottom sheet)
  void _openQuickAdd(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Tekstlauks jaunam uzdevumam
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ierakstiet jaunu uzdevumu šeit',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.check),
                    label: const Text('Pievienot'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                    label: const Text('Atcelt'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
