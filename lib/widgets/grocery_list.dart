import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-shoppinglist-bbaf1-default-rtdb.firebaseio',
      'shopping-list.json',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data \nPlease try after some time';
        });
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (err) {
      setState(() {
          _error = 'Something went wrong!\nPlease try after some time';
        });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem value) async {
    int index = _groceryItems.indexOf(value);
    setState(() {
      _groceryItems.remove(value);
    });
    final url = Uri.https(
      'flutter-shoppinglist-bbaf1-default-rtdb.firebaseio.com',
      'shopping-list/${value.id}.json',
    );
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget groceryScreen = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Oops Nothing to show...',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 30,
                ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Try adding some groceries',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 20,
                ),
          )
        ],
      ),
    );
    if (_isLoading) {
      groceryScreen = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty) {
      groceryScreen = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index]),
          background: Container(
            color: _groceryItems[index].category.color,
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text('${_groceryItems[index].quantity}'),
          ),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
        ),
      );
    }
    if (_error != null) {
      groceryScreen = Center(
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 25,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: groceryScreen,
    );
  }
}
