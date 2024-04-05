import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'marketplace_item.dart'; // Your MarketplaceItem model
import 'package:cached_network_image/cached_network_image.dart';
import 'auth/constants.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Assume we have a function to fetch details for a single sold item, including the buyer's email and rating.
Future<Map<String, dynamic>?> fetchSoldItemDetails(String itemId, String transactionRefId) async {
  try {
    DocumentSnapshot transactionSnapshot = await FirebaseFirestore.instance
        .collection('itemHistory')
        .doc(itemId)
        .collection('transactions')
        .doc(transactionRefId)
        .get();

    if (transactionSnapshot.exists && transactionSnapshot.data() is Map<String, dynamic>) {
      Map<String, dynamic> transactionData = transactionSnapshot.data() as Map<String, dynamic>;
      String buyerEmail = transactionData['buyer'];

      DocumentSnapshot buyerSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(buyerEmail)
          .get();

      if (buyerSnapshot.exists && buyerSnapshot.data() is Map<String, dynamic>) {
        Map<String, dynamic> buyerData = buyerSnapshot.data() as Map<String, dynamic>;
        double buyerRating = buyerData['buyerRating']?.toDouble() ?? 0.0;

        return {
          'buyerEmail': buyerEmail,
          'buyerRating': buyerRating,
        };
      }
    }
  } catch (e) {
    print("Error fetching sold item details: $e");
  }
  return null;
}



Future<List<String>> fetchUserSoldItems(String userEmail) async {
  final currentEmail = FirebaseAuth.instance.currentUser!.email!;
  print(currentEmail);

  final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userEmail).get();
  if (userDoc.exists) {
    final data = userDoc.data();
    // Initialize an empty list to store the itemIds
    List<String> soldItemIds = [];
    // Check if 'soldItems' exists and is a list
    if (data?['soldItems'] != null && data!['soldItems'] is List) {
      // Iterate through the list of maps
      for (var item in data['soldItems']) {
        // Check if the map contains the 'itemId' key
        if (item is Map<String, dynamic> && item.containsKey('itemId')) {
          // Add the itemId to the list
          soldItemIds.add(item['itemId']);
        }
      }
    }
    return soldItemIds;
  }
  return [];
}

Future<void> showRatingDialog(BuildContext context, String buyerId, String transactionId, double newRating) async {
  // Show the dialog asking the user to confirm their rating
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // User must tap button to dismiss
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Confirm Rating'),
        content: Text('Are you sure you want to submit this rating?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Dismiss the dialog
            },
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () async {
              // Call the function to update the rating in Firestore
               updateBuyerRating(buyerId, transactionId, newRating);
              Navigator.of(dialogContext).pop(); // Dismiss the dialog
            },
          ),
        ],
      );
    },
  );
}


void updateBuyerRating(String buyerId, String transactionId, double newRating) async {
  final DocumentReference buyerRef = FirebaseFirestore.instance.collection('Users').doc(buyerId);
  final DocumentSnapshot buyerDoc = await buyerRef.get();

  if (buyerDoc.exists && buyerDoc.data() is Map<String, dynamic>) {
    Map<String, dynamic> data = buyerDoc.data() as Map<String, dynamic>;
    double currentBuyerRating = data['buyerRating']?.toDouble() ?? 0.0;
    int buyerRatingAmount = data['buyerRatingAmount']?.toInt() ?? 0;
    Map<String, double> transactionRatings = Map<String, double>.from(data['transactionRatings'] ?? {});

    if (!transactionRatings.containsKey(transactionId)) {
      // New rating
      transactionRatings[transactionId] = newRating;
      double totalRating = currentBuyerRating * buyerRatingAmount + newRating;
      buyerRatingAmount++; // Increment since it's a new rating
      currentBuyerRating = totalRating / buyerRatingAmount;
    } else {
      // Updating existing rating
      double oldRating = transactionRatings[transactionId]!;
      // Calculate total rating sum as if the old rating was not there
      double totalRating = (currentBuyerRating * buyerRatingAmount) - oldRating;
      // Add the new rating to get the updated total sum
      totalRating += newRating;
      // Average remains the same, no need to increment buyerRatingAmount
      currentBuyerRating = totalRating / buyerRatingAmount;
      transactionRatings[transactionId] = newRating; // Update with the new rating
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(buyerRef, {
        'buyerRating': currentBuyerRating,
        'buyerRatingAmount': buyerRatingAmount,
        'transactionRatings': transactionRatings,
      });
    });
  } else {
    print("Buyer document not found or data format is incorrect.");
  }
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


Future<String> fetchTransactionRefIdForItem(String userEmail, String targetItemId) async {
  // Attempt to fetch the user document from Firestore
  DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(userEmail).get();

  if (userDoc.exists && userDoc.data() is Map<String, dynamic>) {
    var userData = userDoc.data() as Map<String, dynamic>;
    List<dynamic> soldItems = userData['soldItems'] ?? [];

    // Iterate through each sold item to find the matching itemId
    for (var item in soldItems) {
      if (item is Map<String, dynamic> && item['itemId'] == targetItemId) {
        // If a match is found, return the associated transactionRefId
        return item['transactionRefId'];
      }
    }
  }
  return '';

}


class SellerItemsPage extends StatefulWidget {
  @override
  _SellerItemsPageState createState() => _SellerItemsPageState();
}

class _SellerItemsPageState extends State<SellerItemsPage> {
  final user = FirebaseAuth.instance.currentUser;
  Future<List<MarketplaceItem>>? soldItemsFuture;

  @override
  void initState() {
    currentEmail = FirebaseAuth.instance.currentUser!.email!;
    super.initState();
    if (user != null) {
      soldItemsFuture = fetchUserSoldItems(currentEmail).then(fetchMarketplaceItems);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Ensure 'theme' is defined in your code or replace it with a direct color reference.
        backgroundColor: theme,
        centerTitle: true,
        title: Text('My Sold Items'),
      ),
      body: FutureBuilder<List<MarketplaceItem>>(
        future: soldItemsFuture, // Ensure this future is initialized in initState or elsewhere.
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

              // Assuming 'currentEmail' is available and correct.
              return FutureBuilder<String?>(
                future: fetchTransactionRefIdForItem(currentEmail, item.id),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Loading...'));
                  }
                  if (!transactionSnapshot.hasData) {
                    return ListTile(title: Text('Transaction ID not found'));
                  }

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: fetchSoldItemDetails(item.id, transactionSnapshot.data!),
                    builder: (context, detailsSnapshot) {
                      if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                        return ListTile(title: Text('Fetching buyer info...'));
                      }
                      if (!detailsSnapshot.hasData) {
                        return ListTile(title: Text('Buyer details not found'));
                      }

                      // Extract buyer rating and email
                      double buyerRating = detailsSnapshot.data?['buyerRating']?.toDouble() ?? 0.0;
                      String buyerEmail = detailsSnapshot.data?['buyerEmail'] ?? 'Unknown';

                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text('Buyer: $buyerEmail\nRating: $buyerRating'),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrls.first,
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        trailing: RatingBar.builder(
                          itemSize: 20,
                          initialRating: buyerRating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 0.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: theme3, // Make sure 'theme3' is defined
                          ),
                          onRatingUpdate: (newRating) {showRatingDialog(context, buyerEmail,transactionSnapshot.data!, newRating);},
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}