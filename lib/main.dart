import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
import 'map_screen.dart'; // Import the existing map screen
import 'sign_up_screen.dart'; // Import the sign-up screen
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CreateSessionScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBQI257MgWEVzi9tg0RBr4I0HU4EpJ4M4c",
        authDomain: "attendance-app-2-a9650.firebaseapp.com",
        projectId: "attendance-app-2-a9650",
        storageBucket: "attendance-app-2-a9650.firebasestorage.app",
        messagingSenderId: "445362182004",
        appId: "1:445362182004:web:fef4126c9d03edb64cfe21",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool isDarkMode = true; // Default to dark mode

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners(); // Updates the UI immediately
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: LoginPage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = "";

  /*
  Future<void> _signInWithEmail() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _userIdController.text,
        password: _passwordController.text,
      );
      setState(() {
        _message = "Login successful";
      });
      // Navigate to HomePage after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message =
            "Firebase Error: ${e.code} - ${e.message}"; // Catches Firebase-specific errors
      });
    } catch (e) {
      setState(() {
        _message = "Error: $e"; // Catches any other errors
      });
    }
  }
*/
  final FirebaseService firebaseService =
      FirebaseService(); // Instance of FirebaseService

  Future<void> _signInWithEmail() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _userIdController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          String role = userDoc['role'];

          // Show success message
          setState(() {
            _message = "Login Successful!";
          });

          if (role == 'faculty') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        } else {
          setState(() {
            _message = "User role not found";
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = "Firebase Error: ${e.code} - ${e.message}";
      });
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    }
  }

  /*
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      setState(() {
        _message = "Google Sign-In successful";
      });
      // Navigate to HomePage after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = "Error: ${e.message}"; // Display the exact error message
      });
    } catch (e) {
      setState(() {
        _message = "Google Sign-In failed";
      });
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Page")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithEmail,
              child: Text("Login with Email"),
            ),
            /*
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Text("Sign in with Google"),
            ),*/
            // Sign Up navigation button added here:
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text("Don't have an account? Sign up"),
            ),

            SizedBox(height: 20),
            Text(_message, style: TextStyle(color: Colors.red, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; //default page is HomeScreen

  static final List<Widget> _pages = <Widget>[
    HomeScreen(),
    StudentHistoryScreen(),
    ProfileScreen(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures all icons are visible
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Column(
        children: [
          Expanded(
            child: MapScreen(), // Integrate the existing MapScreen
          ),
        ],
      ),
    );
  }
}

class StudentHistoryScreen extends StatefulWidget {
  @override
  _StudentHistoryScreenState createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // Get current user
    String currentUserId = FirebaseAuth.instance.currentUser!.email!.substring(
      0,
      8,
    );

    return Scaffold(
      appBar: AppBar(title: Text("Attendance History")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('sessions')
                .orderBy('date', descending: true)
                .snapshots(),
        builder: (context, sessionSnapshot) {
          if (!sessionSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var sessions = sessionSnapshot.data!.docs;

          Map<String, int> totalSessionsPerClass = {};
          Map<String, int> attendedSessionsPerClass = {};

          return FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('attendance')
                    .where('user_id', isEqualTo: currentUserId)
                    .get(),
            builder: (context, attendanceSnapshot) {
              if (!attendanceSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var attendedSessions = attendanceSnapshot.data!.docs;
              Set<String> attendedSessionIds =
                  attendedSessions
                      .map((doc) => doc['session_id'] as String)
                      .toSet();

              for (var session in sessions) {
                String classId = session['class_id'];
                totalSessionsPerClass[classId] =
                    (totalSessionsPerClass[classId] ?? 0) + 1;
                if (attendedSessionIds.contains(session.id)) {
                  attendedSessionsPerClass[classId] =
                      (attendedSessionsPerClass[classId] ?? 0) + 1;
                }
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Large Attendance Summary Card
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Card(
                        color: const Color.fromARGB(255, 119, 24, 183),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                totalSessionsPerClass.keys.map((classId) {
                                  int total = totalSessionsPerClass[classId]!;
                                  int attended =
                                      attendedSessionsPerClass[classId] ?? 0;
                                  double percentage =
                                      total > 0 ? (attended / total) * 100 : 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Text(
                                      "$classId: ${percentage.toStringAsFixed(2)}% Attendance",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                    // Sessions Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Same as admin's UI
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        var session = sessions[index];
                        String sessionId = session.id;
                        String className = session['class_id'];
                        String date = session['date'];
                        String startTime = session['start_time'];
                        String endTime = session['end_time'];

                        return FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('attendance')
                                  .where('session_id', isEqualTo: sessionId)
                                  .where('user_id', isEqualTo: currentUserId)
                                  .get(),
                          builder: (context, attendanceSnapshot) {
                            if (!attendanceSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }

                            bool isPresent =
                                attendanceSnapshot.data!.docs.isNotEmpty;
                            Color cardColor =
                                isPresent
                                    ? Colors.green[800]!
                                    : Colors.red[800]!;

                            return Card(
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Class: $className",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Date: $date",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      "$startTime - $endTime",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      isPresent ? "Present ✅" : "Absent ❌",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String newPassword = passwordController.text.trim();
                String confirmPassword = confirmPasswordController.text.trim();

                if (newPassword.isEmpty || newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password must be at least 6 characters."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Passwords do not match."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _auth.currentUser?.updatePassword(newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Student Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            user?.photoURL != null
                ? CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user!.photoURL!),
                )
                : const Icon(Icons.person, size: 80),
            const SizedBox(height: 10),
            Text(
              "Email: ${user?.email ?? 'No email found'}",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _changePassword(context),
              child: const Text("Change Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dark Mode", style: TextStyle(fontSize: 18)),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    MapScreen(),
    CreateSessionScreen(), // Add the Create Session screen here
    AdminHistoryScreen(),
    AdminProfileScreen(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Set Up'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AdminHistoryScreen extends StatefulWidget {
  @override
  _AdminHistoryScreenState createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance History")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('sessions')
                .orderBy('date', descending: true) // Sort by latest date first
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var sessions = snapshot.data!.docs;

          return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns of session icons
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              var session = sessions[index];
              String sessionId = session.id;
              String classId = session['class_id'];
              String date = session['date'];
              String startTime = session['start_time'];
              String endTime = session['end_time'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AttendanceDetailScreen(sessionId: sessionId),
                    ),
                  );
                },
                child: Card(
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Class: $classId",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Date: $date",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "$startTime - $endTime",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String newPassword = passwordController.text.trim();
                String confirmPassword = confirmPasswordController.text.trim();

                if (newPassword.isEmpty || newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password must be at least 6 characters."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Passwords do not match."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _auth.currentUser?.updatePassword(newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Faculty Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            user?.photoURL != null
                ? CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user!.photoURL!),
                )
                : const Icon(Icons.person, size: 80),
            const SizedBox(height: 10),
            Text(
              "Email: ${user?.email ?? 'No email found'}",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _changePassword(context),
              child: const Text("Change Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signOut(context),
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceDetailScreen extends StatelessWidget {
  final String sessionId;
  AttendanceDetailScreen({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance Details")),
      body: FutureBuilder<QuerySnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          //Extract user IDs from 'email' field instead of document ID
          List<String> allUserIds =
              userSnapshot.data!.docs
                  .map(
                    (doc) => doc['email'].toString().substring(0, 8),
                  ) // Extract first 8 characters
                  .toList();

          // Sort the IDs numerically
          allUserIds.sort((a, b) => a.compareTo(b)); // Sort alphabetically

          return FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('attendance')
                    .where('session_id', isEqualTo: sessionId)
                    .get(),
            builder: (context, attendanceSnapshot) {
              if (!attendanceSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              List<String> presentUsers =
                  attendanceSnapshot.data!.docs
                      .map((doc) => doc['user_id'].toString())
                      .toList();

              return ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: allUserIds.length,
                itemBuilder: (context, index) {
                  String userId = allUserIds[index];
                  bool isPresent = presentUsers.contains(userId);

                  return Card(
                    color: isPresent ? Colors.green[800] : Colors.red[800],
                    child: ListTile(
                      title: Text(
                        "User ID: $userId",
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        isPresent ? "Present" : "Absent",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
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
