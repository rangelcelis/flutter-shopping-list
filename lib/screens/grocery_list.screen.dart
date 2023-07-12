import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item.screen.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final response = await http.get(
      Uri.https('flutter-prep-21920-default-rtdb.firebaseio.com',
          'shopping-list.json'),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode >= 400) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    final Map<String, dynamic> data = json.decode(response.body) ?? {};

    final List<GroceryItem> tempData = [];
    for (var item in data.entries) {
      Category category = categories.entries
          .firstWhere(
            (element) => element.value.name == item.value['category'],
          )
          .value;

      tempData.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: int.parse(item.value['quantity']),
          category: category,
        ),
      );
    }

    setState(() {
      _groceryItems = tempData;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const NewItemScreen(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    bool wasRemoved = false;

    final response = await http.delete(Uri.https(
        'flutter-prep-21920-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json'));

    if (response.statusCode == 200) {
      setState(() {
        _groceryItems.remove(item);
      });

      wasRemoved = true;
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasRemoved
            ? '${item.name} removed from list.'
            : 'Something went wrong. Try again later.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Text(
        _hasError ? 'Something went wrong. Try again later.' : 'No items yet!',
        style: const TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) {
          final item = _groceryItems[index];

          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) => _removeItem(item),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 4,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.square, color: item.category.color),
              title: Text(item.name),
              trailing: Text('${item.quantity}'),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: content,
    );
  }
}
