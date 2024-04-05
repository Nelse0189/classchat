import 'package:flutter/material.dart';
import 'marketplace_item.dart';
import 'upload_item.dart'; // Make sure this is the correct import for your UploadItem page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/constants.dart';
import 'itemdetailpage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auth/register_page.dart';
import 'package:shimmer/shimmer.dart';
class MarketPlace extends StatefulWidget {
  const MarketPlace({super.key});

  @override
  State<MarketPlace> createState() => _MarketPlaceState();
}

class _MarketPlaceState extends State<MarketPlace> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _selectedCategory = 'All'; // Default to 'All' or null if you prefer no initial filter
  double _minPrice = 0.0;
  double _maxPrice = 250.00; // Adjust this as needed based on your item price range
  List<String> categories = ['All','Electronics',
    'Fashion',
    'Home & Garden',
    'Sports',
    'Toys & Hobbies',
    'Motors',
    'Collectibles & Art',
    'Industrial Equipment',]; // Example categories
  // Adjust this max price as needed

  // Placeholder list of items

  TextEditingController searchController = TextEditingController();

  List<MarketplaceItem> items = [];

  List<MarketplaceItem> filteredItems = [];

  StreamSubscription? _sub;

  Future<bool> checkUserHasStripeAccount2(String email) async {
    // Access FirebaseFunctions instance
    FirebaseFunctions functions = FirebaseFunctions.instance;

    // Create a callable function with the exact name as defined in Firebase
    HttpsCallable callable = functions.httpsCallable('checkStripeAccount');

    try {
      // Call the function with required parameters
      final result = await callable.call({'email': email});

      // Use the data returned from the function
      bool hasAccount = result.data['hasAccount'];
      print("Has Stripe Account: $hasAccount");
      return hasAccount;
    } catch (e) {
      // Handle errors or exceptions
      print("Error calling checkStripeAccount: $e");
      return false;
    }
  }

  void filterCategoryItems() {
    setState(() {
      // Check if _selectedCategory is 'All', if so, do not filter by category
      if (_selectedCategory == 'All') {
        filteredItems = items.where((item) {
          final itemPrice = double.parse(item.price) / 100; // Assuming price is in cents
          return itemPrice >= _minPrice && itemPrice <= _maxPrice;
        }).toList();
      } else {
        // If _selectedCategory is not 'All', filter both by category and price range
        filteredItems = items.where((item) {
          final itemPrice = double.parse(item.price) / 100; // Assuming price is in cents
          return item.category == _selectedCategory &&
              itemPrice >= _minPrice &&
              itemPrice <= _maxPrice;
        }).toList();
      }
    });
  }



  void showConfirmationDialog(String accountId, String userEmail) {
    // Showing a simple dialog for confirmation
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Account Setup"),
          content: Text("Please confirm that you have finished setting up your Stripe account."),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Confirm"),
              onPressed: () async {
                await uploadStripeAccountId(accountId, userEmail);
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  String formatPrice(String priceCents) {
    // Convert the price from a string to an integer
    int cents = int.parse(priceCents);
    // Convert cents to a decimal number representing dollars
    double dollars = cents / 100.0;
    // Format the number as a string with two decimal places
    return dollars.toStringAsFixed(2);
  }


  Future<void> uploadStripeAccountId(String accountId, String userEmail) async {
    final firestoreInstance = FirebaseFirestore.instance;
    await firestoreInstance.collection('Users').doc(userEmail).set({
      'stripeAccountId': accountId,
    }, SetOptions(merge: true)).then((_) {
      print("Stripe account ID uploaded successfully!");
    }).catchError((error) {
      print("Failed to upload Stripe account ID: $error");
    });
  }

  Future<bool> checkUserHasStripeAccount() async {
    try {
      // Get the user's document from Firestore
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentEmail).get();

      if (!userDoc.exists) {
        print("User document not found.");
        return false;
      }

      // Check if the StripeAccountId field exists and is not empty
      final stripeAccountId = userDoc.get('stripeAccountId');
      print(currentEmail + 'body');
      if (stripeAccountId != null && stripeAccountId is String && stripeAccountId.isNotEmpty) {
        print("User has a Stripe account with ID: $stripeAccountId");
        return true;
      } else {
        print("User does not have a Stripe account.");
        return false;
      }
    } catch (e) {
      print("Error checking user's Stripe account: $e");
      return false;
    }
  }
  Future<void> onboardSeller(String currentEmail) async {
    // Replace with your actual backend endpoint to check if the user has a Stripe account
    /*final checkResponse = await http.post(
      Uri.parse('https://us-central1-class-17dde.cloudfunctions.net/checkStripeAccount'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': currentEmail,
      }),
    );

    final checkJsonResponse = jsonDecode(checkResponse.body);
    //print("hi" + jsonDecode(checkResponse.body).toString());
    //showConfirmationDialog(checkJsonResponse['accountId'], currentEmail);
    if (checkJsonResponse['hasAccount'] == true) {
      // User already has a Stripe account, proceed without redirection
      print("User already has a Stripe account. No need to create a new one.");
    } *//*else {*/
    // No Stripe account found for this email, proceed to create a new account
    final response = await http.post(
      Uri.parse('https://us-central1-class-17dde.cloudfunctions.net/createExpressAccount'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': currentEmail,
      }),
    );
    print('hi1');
    print(jsonDecode(response.body).toString());
    final jsonResponse = jsonDecode(response.body);
    print('hi');
    if (jsonResponse['url'] != null) {
      final Uri launchUri = Uri.parse(jsonResponse['url']);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);


      } else {
        print('Could not launch $launchUri');
        throw 'Could not launch $launchUri';
      }
    }
  }




  void filterItems() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredItems = List.from(items); // Show all items if search query is empty
      });
    } else {
      final filtered = items.where((item) {
        return item.title.toLowerCase().contains(query);
      }).toList();

      setState(() {
        filteredItems = filtered;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    if(FirebaseAuth.instance.currentUser != null) {
      currentEmail = FirebaseAuth.instance.currentUser!.email!;
      currentUser = FirebaseAuth.instance.currentUser;
    }
    fetchItems();
    filteredItems = List.from(items); // Initialize with all items
    searchController.addListener(filterItems);
  }

  @override
  void dispose() {
    searchController.dispose();
    _sub?.cancel();
    super.dispose();
  }




  Future<void> fetchItems() async {
    try {
      final QuerySnapshot itemSnapshot =
      await FirebaseFirestore.instance.collection('items').get();

      final List<MarketplaceItem> fetchedItems = itemSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MarketplaceItem(
          id: doc.id,
          imageUrls: List<String>.from(data['images'] ?? []),
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          price: data['price'] ?? '',
          seller: data['userId']?? '',
          sellerName: data['userName']??'',
          amount: data['amount'] ?? 0,
          category: data['category'] ?? '',
        );
      }).toList();

      setState(() {
        items = fetchedItems;
        filteredItems = List.from(items); // Also initialize filteredItems with all fetched items
      });
    } catch (e) {
      print("Error fetching items: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: theme,
        leading: IconButton(
          icon: Icon(Icons.menu), // The menu icon
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
        titleTextStyle: TextStyle(fontFamily: 'sfPro', color: Colors.white, fontSize: 20),
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white, fontFamily: 'sfPro'),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: theme2,
      body: Stack(
        children: [
          Positioned.fill(
            child: Shimmer.fromColors(
              baseColor: theme2,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: theme2,
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filteredItems.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Number of columns
              crossAxisSpacing: 10, // Horizontal space between items
              mainAxisSpacing: 10, // Vertical space between items
              childAspectRatio: 0.8, // Aspect ratio of the cards
            ),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ItemDetailPage(item: item),
                    ),
                  );
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: GridTile(
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrls[0],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(), // Optional
                        errorWidget: (context, url, error) =>
                            Icon(Icons.error), // Optional
                      ),
                      footer: GridTileBar(
                        backgroundColor: Colors.black54,
                        title: Text(item.title, style: TextStyle(
                            fontFamily: 'SFPro', fontSize: 16)),
                        subtitle: Text('\$${formatPrice(item.price)}',
                            style: TextStyle(
                                fontFamily: 'SFPro', fontSize: 12)),
                      ),
                    ),
                  ),
                ),
              );
            },
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // Show the progress indicator dialog
          showDialog(
            context: context,
            barrierDismissible: false, // Prevents the dialog from closing on tap outside
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent, // Makes the dialog's background transparent
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color for the dialog
                    borderRadius: BorderRadius.circular(10), // Rounds the corners of the dialog
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Makes the dialog's height fit its content
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15), // Space between indicator and text
                      Text("Please wait..."),
                    ],
                  ),
                ),
              );
            },
          );

          if(currentUser != null) {
            if (!await checkUserHasStripeAccount()) {
              // Close the dialog before navigating or performing other actions
              Navigator.pop(context); // Close the prxscdw x@MANbV gress dialog
              onboardSeller(currentEmail);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ItemUploadPage(
                    onItemUploaded: () async {
                      await fetchItems(); // Fetch new items or refresh the list
                    },
                  ),
                ),
              ).then((_) {
                // Optionally, check if the item was uploaded and fetch new items
                Navigator.pop(context); // Close the progress dialog if it's still open
              });
            }
          } else if(currentUser == null) {
            print(currentUser.toString());
            // Close the dialog before showing the snackbar
            Navigator.pop(context); // Close the progress dialog
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
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme),
              child: Text('Filter Options', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'sfPro')),
            ),
            ListTile(
              title: Text('Category'),
              trailing: DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                    filterCategoryItems();
                  });
                },
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              title: Text("Price Range"),
              subtitle: RangeSlider(
                activeColor: theme3,
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 250,
                divisions: 20,
                labels: RangeLabels(_minPrice.toStringAsFixed(2), _maxPrice.toStringAsFixed(2)),
                onChanged: (RangeValues values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                    filterCategoryItems();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
