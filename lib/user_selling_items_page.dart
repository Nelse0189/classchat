import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'marketplace_item.dart'; // Your MarketplaceItem model
import 'package:cached_network_image/cached_network_image.dart';
import 'auth/constants.dart';



Future<List<String>> fetchUserSoldItems(String userEmail) async {
  currentEmail = FirebaseAuth.instance.currentUser!.email!;
  print(currentEmail);
  final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userEmail).get();
  if (userDoc.exists) {
    final soldItems = List<String>.from(userDoc.data()?['userItems'] ?? []);
    return soldItems;
  }
  return [];
}

String formatPrice(String priceCents) {
  // Convert the price from a string to an integer
  int cents = int.parse(priceCents);
  // Convert cents to a decimal number representing dollars
  double dollars = cents / 100.0;
  // Format the number as a string with two decimal places
  return dollars.toStringAsFixed(2);
}

Future<List<MarketplaceItem>> fetchMarketplaceItems(List<String> itemIds) async {
  List<MarketplaceItem> items = [];
  for (String id in itemIds) {
    final doc = await FirebaseFirestore.instance.collection('itemHistory').doc(id).get();
    if (doc.exists) {
      items.add(MarketplaceItem.fromDocument(doc));
    }
  }
  return items;
}

class UserItemsPage extends StatefulWidget {
  final String userEmail;

  const UserItemsPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _UserItemsPageState createState() => _UserItemsPageState();
}

class _UserItemsPageState extends State<UserItemsPage> {
  Future<List<MarketplaceItem>>? soldItemsFuture;

  @override
  void initState() {
    currentEmail = FirebaseAuth.instance.currentUser!.email!;
    super.initState();
    soldItemsFuture = fetchUserSoldItems(widget.userEmail).then(fetchMarketplaceItems);
  }

  Future<void> deleteItem(String itemId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Item Options'),
          content: Text('Do you want to delete this item or change its amount?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteItemConfirmed(itemId);
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                promptChangeItemAmount(itemId);
              },
              child: Text('Change Amount'),
            ),
          ],
        );
      },
    );
  }

  Future<void> promptChangeItemAmount(String itemId) async {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Item Amount'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(hintText: 'Enter new amount'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  final newAmount = int.tryParse(amountController.text);
                  if (newAmount != null) {
                    changeItemAmount(itemId, newAmount);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid number.')),
                    );
                  }
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> changeItemAmount(String itemId, int newAmount) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({
        'amount': newAmount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item amount updated successfully.')),
      );

      // Optionally, refresh the list of items or update the UI
      setState(() {
        soldItemsFuture = fetchUserSoldItems(widget.userEmail).then(fetchMarketplaceItems);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating the item.')),
      );
    }
  }

  Future<void> deleteItemConfirmed(String itemId) async {

    try {
      // Delete the item from the 'items' collection
      await FirebaseFirestore.instance.collection('items').doc(itemId).delete();
      await FirebaseFirestore.instance.collection('itemHistory').doc(itemId).delete();

      // Remove the item ID from the 'userItems' field in the user's document
      await FirebaseFirestore.instance.collection('Users').doc(widget.userEmail).update({
        'userItems': FieldValue.arrayRemove([itemId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item deleted successfully.')),
      );

      // Refresh the list of items or update the UI accordingly
      setState(() {
        soldItemsFuture = fetchUserSoldItems(widget.userEmail).then(fetchMarketplaceItems);
      });
    } catch (e) {
      print(e); // Consider logging to a service or console for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while deleting the item.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme,
        centerTitle: true,
        title: Text('My Items'),
      ),
      body: FutureBuilder<List<MarketplaceItem>>(
        future: soldItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No sold items found.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text('\$${formatPrice(item.price)}'),
                leading: item.imageUrls.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), // Adjust the radius here
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrls.first,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    width: 100, // Specify the width
                    height: 100, // Specify the height, if necessary
                    fit: BoxFit.cover,
                  ),
                )
                    : null,
                onTap: () => deleteItem(item.id),
              );
            },
          );
        },
      ),
    );
  }
}

