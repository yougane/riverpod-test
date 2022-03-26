import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Riverpod Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    debugPrint('Building list');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (final item in items)
                    // We are passing the item data to its widget via the BuildContext using an InheritedWidget.
                    // This way, we can use a const constructor to instantiate the item widget in order to avoid unnecessary rebuilds for every item in the list
                    // and only rebuild an item when its data changes.
                    InheritedItem(
                      key: ValueKey(item.id),
                      item: item,
                      onToggled: (value) => ref
                          .read(itemsProvider.notifier)
                          .toggleStatus(item.id),
                      onRemoved: () =>
                          ref.read(itemsProvider.notifier).remove(item.id),
                      child: const ItemWidget(),
                    ),
                ],
              ),
            ),
            FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                final itemId = items.length + 1;
                ref.read(itemsProvider.notifier).add(Item(
                      id: itemId,
                      title: 'Item #$itemId',
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class Item extends Equatable {
  const Item({required this.id, required this.title, this.isActive = false});

  final int id;
  final String title;
  final bool isActive;

  @override
  List<Object?> get props => [id, title, isActive];
}

class ItemsNotifier extends StateNotifier<List<Item>> {
  ItemsNotifier() : super([]);

  void add(Item item) {
    state = [...state, item];
  }

  void remove(int id) {
    state = [
      for (final item in state)
        if (item.id != id) item,
    ];
  }

  void toggleStatus(int id) {
    state = [
      for (final item in state)
        if (item.id == id)
          Item(id: item.id, title: item.title, isActive: !item.isActive)
        else
          item
    ];
  }
}

final itemsProvider = StateNotifierProvider<ItemsNotifier, List<Item>>((ref) {
  return ItemsNotifier();
});

class InheritedItem extends InheritedWidget {
  const InheritedItem({
    Key? key,
    required this.item,
    required Widget child,
    this.onToggled,
    this.onRemoved,
  }) : super(key: key, child: child);

  final Item item;
  final void Function(bool?)? onToggled;
  final void Function()? onRemoved;

  static InheritedItem? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedItem>();
  }

  // Update an item only when its data has changed
  @override
  bool updateShouldNotify(covariant InheritedItem oldWidget) {
    return oldWidget.item != item;
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inheritedItem = InheritedItem.of(context);
    if (inheritedItem == null) {
      return Container();
    }

    final item = inheritedItem.item;
    final onToggled = inheritedItem.onToggled;
    final onRemoved = inheritedItem.onRemoved;

    debugPrint('Building item #${item.id}');

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
            ),
          ),
          const Spacer(),
          Checkbox(
            value: item.isActive,
            onChanged: onToggled,
          ),
          IconButton(
            onPressed: onRemoved,
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
    );
  }
}
