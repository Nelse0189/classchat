import 'package:classchat/auth/register_page.dart';
import 'package:flutter/material.dart';
import 'marketplace_item.dart'; // Your updated MarketplaceItem model
import 'package:flutter_stripe/flutter_stripe.dart';
import 'auth/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth/constants.dart';
import 'message_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'full_screen_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'dart:async';

class ItemDetailPage extends StatefulWidget {
  final MarketplaceItem item;


  const ItemDetailPage({Key? key, required this.item}) : super(key: key);

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  Future<void> initPaymentSheet(context, {required String sellerEmail, required String email, required String amount}) async {
    try{
      String? currentEmail = FirebaseAuth.instance.currentUser?.email;
      if (currentEmail == null) {
        // Handle the error, perhaps return or show a message
        return;
      }


      //print(sellerEmail + email + amount.toString());
      final response = await http.post(
        Uri.parse(
            'https://us-central1-class-17dde.cloudfunctions.net/createDirectCharge'
        ),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String,String>{
          'email': email,
          'customer': email,
          'application_fee_amount': amount,
          'amount': amount,
          'stripeAccount': sellerEmail,
        }),);
      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse.toString());

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          // Set to true for custom flow
          customFlow: false,
          // Main params
          merchantDisplayName: 'Flutter Stripe Store Demo',
          paymentIntentClientSecret: jsonResponse['paymentIntent'],
          // Customer keys
          customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
          customerId: jsonResponse['customer'],
          // Extra options
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'US',
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
          ),
          style: ThemeMode.dark,
        ),
      );
      print('yoo');
      await Stripe.instance.presentPaymentSheet();
      print('scod');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment completed')),
      );
      String? buyerEmail = FirebaseAuth.instance.currentUser?.email;
      if (buyerEmail == null) {
        // Handle the case where there is no user or no email
        return;
      }
      String itemId = widget.item.id; // Get the itemId from widget.item

// Update the buyer field in the Firestore document for the item
      await updateItemBuyer(itemId, buyerEmail);

      DocumentReference DocRef = await addItemToBuyerBoughtItems(currentEmail, widget.item.id);
      await addItemToSellerSoldItems(sellerEmail, widget.item.id, DocRef);
      reduceItemAmountByOne(widget.item.id);
    } catch (e){
      print('Error: $e');
    }
    /*on StripeException catch(e) {
      // Check if the payment was cancelled by the user
      if(e.error.code == 'FailureCode.Canceled') {
        // User cancelled the payment sheet, do not show Snackbar
        print('Payment cancelled by user.');
      } else {
        // Handle other Stripe exceptions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } catch(e) {
      // Handle any other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }*/
  }

  Future<void> updateItemBuyer(String itemId, String buyerEmail) async {
    try {
      // Reference to the item document in Firestore
      DocumentReference itemRef = FirebaseFirestore.instance.collection('itemHistory').doc(itemId);

      // Update the 'buyer' field of the item document
      await itemRef.update({'buyer': buyerEmail});

      print("Item buyer updated successfully.");
    } catch (e) {
      print("Error updating item buyer: $e");
    }
  }


  Future<void> deleteItem() async {
    try {
      // Get the current user's email
      String? currentUserEmail = FirebaseAuth.instance.currentUser?.email!;
      if (currentUserEmail == null) {
        print('No logged-in user');
        return; // Or handle appropriately
      }
      // Check if the current user is the owner of the item
      if (widget.item.seller == currentUserEmail) {
        // Delete the item from the Firestore 'items' collection
        await FirebaseFirestore.instance.collection('items').doc(widget.item.id).delete();
        //await FirebaseFirestore.instance.collection('itemHistory').doc(widget.item.id).delete();
        await FirebaseFirestore.instance.collection('Users').doc(currentEmail).update({
          'userItems': FieldValue.arrayRemove([widget.item.id]),
        });
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item deleted successfully')),
        );
        // Optionally, navigate back to the previous page or home page
        Navigator.pop(context);
      } else {
        // Show an error message if the current user is not the owner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are not the owner of this item')),
        );
      }
    } catch (e) {
      // Handle errors, e.g., show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }




  Future<DocumentReference> addItemToBuyerBoughtItems(String buyerEmail, String itemId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference buyerRef = firestore.collection('Users').doc(buyerEmail);
    final DocumentReference itemHistoryRef = firestore.collection('itemHistory').doc(itemId);
    Completer<DocumentReference> completer = Completer<DocumentReference>();

    firestore.runTransaction((transaction) async {
      DocumentSnapshot buyerSnapshot = await transaction.get(buyerRef);

      if (!buyerSnapshot.exists) {
        throw Exception("Buyer does not exist!");
      }

      // Initialize currentBoughtItems as an array if it doesn't exist, or retrieve the existing array

      var buyerData = buyerSnapshot.data();
      if (buyerData is Map<String, dynamic>) { // This ensures 'buyerData' is treated as Map<String, dynamic>
        // Now 'containsKey' method is available because 'buyerData' is confirmed to be a Map<String, dynamic>
        List<dynamic> currentBoughtItems = buyerData.containsKey('boughtItems')
            ? List.from(buyerData['boughtItems'])
            : [];

        // If 'boughtItems' doesn't exist or it's your first time initializing it,
        // it would be an empty array as set by the line above. Now you can add to it or initialize it as needed.

        // Example to add a new item to 'boughtItems'
        if (currentBoughtItems.isEmpty) {
          // Initialize 'boughtItems' with a new item if it's your intention
          Map<String, dynamic> newItem = {
            'transactionRefId': 'someTransactionId',
            'itemId': 'someItemId',
          };
        }

        // Create a new document in the 'transactions' subcollection of the itemHistory document
        DocumentReference transactionRef = itemHistoryRef.collection(
            'transactions').doc();
        transaction.set(transactionRef, {
          'itemId': itemId,
          'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
          'buyer': buyerEmail,
          'seller': '',
          // Include any other fields you need here
        });


        // Add a new map to the currentBoughtItems array with the transactionRef ID and itemId
        currentBoughtItems.add({
          'transactionRefId': transactionRef.id,
          // Use the transaction document ID
          'itemId': itemId,
        });

        // Update the buyer's document with the new array of maps
        transaction.update(buyerRef, {'boughtItems': currentBoughtItems});

        // Once the transaction is successfully committed, complete the completer with the transactionRef
        completer.complete(transactionRef);
      }}).catchError((error) {
      print("Failed to add item to buyer's boughtItems or create transaction record in itemHistory: $error");
      completer.completeError(error);
    });

    // Wait for the completer to complete and return the result
    return completer.future;
  }

  Future<int> fetchSellerRatingCount(String sellerId) async {
    try {
      // Access the Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference the seller's document in the Users collection
      final DocumentReference sellerRef = firestore.collection('Users').doc(sellerId);

      // Fetch the seller's document
      final DocumentSnapshot sellerSnapshot = await sellerRef.get();

      // Explicitly cast the document data to Map<String, dynamic>
      final Map<String, dynamic>? sellerData = sellerSnapshot.data() as Map<String, dynamic>?;

      if (sellerData != null && sellerData.containsKey('sellerRatingAmount')) {
        // If the document exists and contains the ratingCount field, return its value
        return sellerData['sellerRatingAmount'];
      } else {
        // If the document does not exist or does not contain the field, return a default value (e.g., 0)
        return 0;
      }
    } catch (e) {
      // In case of an error, log it and return a default value
      print("Error fetching seller's rating count: $e");
      return 0;
    }
  }






  Future<double> fetchSellerRating(String sellerId) async {
    // Assume 'sellerId' is the seller's user ID or email used as the document ID in Firestore
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(sellerId).get();

    if (docSnapshot.exists && docSnapshot.data()!.containsKey('sellerRating')) {
      // Assuming 'sellerRating' is stored as a double
      return docSnapshot.data()!['sellerRating'].toDouble();
    }
    // Return a default rating (e.g., 0 or 3) if no rating exists
    return 0.0;
  }




  Future<void> addItemToSellerSoldItems(String sellerEmail, String itemId, DocumentReference transactionRef) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference sellerRef = firestore.collection('Users').doc(sellerEmail);

    firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(sellerRef);

      if (!snapshot.exists) {
        throw Exception("Seller does not exist!");
      }

      // Initialize currentSoldItems as an array if it doesn't exist, or retrieve the existing array
      List<dynamic> currentSoldItems = snapshot.get('soldItems')?.toList() ?? [];

      // Add a new map to the currentSoldItems array with the transactionRef ID and itemId
      currentSoldItems.add({
        'transactionRefId': transactionRef.id, // Use the transaction document ID
        'itemId': itemId,
      });

      // Update the seller's document with the new array of maps
      transaction.update(sellerRef, {'soldItems': currentSoldItems});

      // Update the specified document in the transactions subcollection
      transaction.update(transactionRef, {
        'seller': sellerEmail, // Include the seller email
        // Add any other fields as needed
      });

    }).catchError((error) {
      print("Failed to add item to seller's soldItems or to update the transaction document: $error");
    });
  }






  void initState() {
    super.initState();
    print (selectedUser);
    selectedUser = widget.item.seller;
  }

  String formatPrice(String priceCents) {
    // Convert the price from a string to an integer
    int cents = int.parse(priceCents);
    // Convert cents to a decimal number representing dollars
    double dollars = cents / 100.0;
    // Format the number as a string with two decimal places
    return dollars.toStringAsFixed(2);
  }

  Future <void> expandImage(String imageUrl)async {
    if(imageUrl.isNotEmpty){
      Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImage(imageUrl: imageUrl,)),);
    }
  }



  Future<bool> isCurrentUserBlockedBySelectedUser() async {
    if(currentUser!=null) {
      try {
        // Fetch the document for the selected user from Firestore
        DocumentSnapshot selectedUserDoc = await userCollections.doc(
            selectedUser).get();
        print(selectedUser);

        if (selectedUserDoc.exists) {
          // Get the blockedUsers list from the selected user's document
          List<dynamic> blockedUsers = selectedUserDoc['blockedUsers'] ?? [];

          // Check if the current user's email is in the blockedUsers list
          String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
          bool isBlocked = !blockedUsers.contains(currentUserEmail);

          return isBlocked;
        } else {
          // If the selected user's document does not exist, assume not blocked
          return false;
        }
      } catch (e) {
        print("Error checking if current user is blocked: $e");
        return false; // In case of error, assume not blocked for safety
      }
    }
    else{
      return false;
    }
  }

  Future<void> reduceItemAmountByOne(String itemId) async {
    final DocumentReference itemRef = FirebaseFirestore.instance.collection('items').doc(itemId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(itemRef);

      if (!snapshot.exists) {
        throw Exception("Item does not exist!");
      }

      int currentAmount = snapshot.get('amount');
      if (currentAmount > 0) {
        transaction.update(itemRef, {'amount': currentAmount - 1});
      } else {
        // Handle the case where the item's amount is already 0
        print("Item is already sold out!");
      }
    }).then((value) {
      print("Item amount reduced by one.");
    }).catchError((error) {
      print("Failed to reduce item amount: $error");
    });
  }


  Future <void> messageSeller(context)async{
    if (FirebaseAuth.instance.currentUser == null){
      print('jbbo');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You must be signed in to use this feature"),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Register',
            onPressed: () {
              // Navigate to your sign-in page
              Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
            },
          ),
        ),
      );
      return;
    }
    currentUser = FirebaseAuth.instance.currentUser;
    selectedUser = widget.item.seller;
    if(await isCurrentUserBlockedBySelectedUser()) {
      if(await isCurrentUserBlockedBySelectedUser()){
        try {
          userCollections.doc(currentUser!.email!).update({
            'Friends': FieldValue.arrayUnion([selectedUser])
          });
          userCollections.doc(selectedUser).update({
            'Friends': FieldValue.arrayUnion([currentUser!.email!])
          });
          Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomePage()),
          );
        } catch (e) {
          print("Error adding friend: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme2,
      appBar: AppBar(
        backgroundColor: theme,
        title: Text(widget.item.title),
        titleTextStyle: TextStyle(fontFamily: 'sfPro', color: Colors.white, fontSize: 20),
        centerTitle: true,// Use item properties
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 40,),
              // Assuming item.imageUrls is a List<String> of URLs
              Container(
                height: 400,
                width: 370, // Adjust the width as needed
                child: Center(
                  child: PageView.builder(
                    itemCount: widget.item.imageUrls.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(15.0), // Adjust this value to change the roundness of the corners
                        child: InteractiveViewer(
                          panEnabled: true, // Set it to false to prevent panning.
                          boundaryMargin: EdgeInsets.all(20), // Adjust the space around the image if needed.
                          minScale: 0.5, // Adjust the minimum scale level.
                          maxScale: 4.0, // Adjust the maximum scale level.
                          child: CachedNetworkImage(
                            imageUrl: widget.item.imageUrls[index],
                            fit: BoxFit.cover, // Maintains the image's aspect ratio
                            placeholder: (context, url) => CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 25), // Adds a little space between the image and the price
              Text('Price: '+'\$${formatPrice(widget.item.price)}'), // Use the formatted price here
              // Display the price
              // Add more details and options here
              SizedBox(height: 8,),
              Text('Description: ' + widget.item.description),
              SizedBox(height: 8,),
              Text('Seller Username: ' + widget.item.sellerName),
              SizedBox(height: 8,),
              Text("Amount left: " + widget.item.amount.toString()),
              SizedBox(height: 8,),
              Text("Item Category: " + widget.item.category.toString()),
              SizedBox(height: 8,),
              FutureBuilder<Map<String, dynamic>>(
                future: Future.wait([
                  fetchSellerRating(widget.item.seller),
                  fetchSellerRatingCount(widget.item.seller)
                ]).then((List responses) => {'rating': responses[0], 'count': responses[1]}),
                builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error fetching rating');
                  }

                  final double rating = snapshot.data?['rating'] ?? 0.0;
                  final int count = snapshot.data?['count'] ?? 0;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (rating) {
                          // This callback would be used if you allow users to rate. Since this is a display-only scenario, it can be ignored.
                        },
                        ignoreGestures: true, // Make the rating bar read-only
                      ),
                      SizedBox(width: 8),
                      Text("($count)"),
                    ],
                  );
                },
              ),
              SizedBox(height: 15,),
              ElevatedButton(
                onPressed: () {
                  // Add functionality to message the user
                  messageSeller(context);
                },
                child: Text('Message Seller',style: TextStyle(fontFamily: 'SfPro'),),
              ),
              SizedBox(height: 8,),
              ElevatedButton(
                onPressed: () {
                  if(currentUser!=null) {
                    currentEmail = FirebaseAuth.instance.currentUser!.email!;
                  }
                  print(widget.item.seller);
                  if(currentUser == null){
                    print('null');
                  }
                  // Add functionality to purchase the item
                  if(widget.item.amount!=0 && FirebaseAuth.instance.currentUser != null) {
                    initPaymentSheet(context, sellerEmail: widget.item.seller,
                        email: currentEmail,
                        amount: widget.item.price);
                  }
                  else if (currentUser == null){
                    print('jobo');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("You must be signed in to use this feature"),
                        duration: Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Register',
                          onPressed: () {
                            // Navigate to your sign-in page
                            Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
                          },
                        ),
                      ),
                    );
                  }
                  else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('The item is sold out')),
                    );
                  }
                },
                child: Text('Purchase',style: TextStyle(fontFamily: 'SfPro'),),
              ),
              const SizedBox(
                height: 8,
              ),
              FirebaseAuth.instance.currentUser?.email == widget.item.seller ? ElevatedButton(
                onPressed: () {
                  // Call the deleteItem method when the button is pressed
                  deleteItem();
                },
                child: Icon(Icons.delete_rounded), // Text color
              ) : Container(),
            ],
          ),
        ),
      ),
    );
  }
}