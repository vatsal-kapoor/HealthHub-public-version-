import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_page.dart'; // Make sure this is the updated FormPage
import 'firebase_options.dart';
import 'package:intl/intl.dart';

class HealthScore {
  DateTime date;
  double score;

  HealthScore(this.date, this.score);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthHUB',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        colorScheme: ColorScheme.fromSwatch(
          accentColor: Colors.cyanAccent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.cyanAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.cyanAccent,
          ),
        ),
      ),
      home: const SignUpChecker(),
    );
  }
}


class SignUpChecker extends StatelessWidget {
  const SignUpChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return const MyHomePage(title: 'HealthHub');
        } else {
          return const AuthPage();
        }
      },
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Authentication")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/image.png'), // This line adds the image
            const SizedBox(height: 20), // Add some space between image and buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpPage()));
              },
              child: const Text("Sign Up"),
            ),
            const SizedBox(height: 10), // Add some space between the buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
              },
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}


class LoginPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to sign in: ${e.toString()}")));
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: "example@company.com",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
            const SizedBox(height: 10), // Adds space between fields
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: "At least 6 characters",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  User? newUser = userCredential.user;
                  if (newUser != null) {
                    await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
                      'email': _emailController.text,
                      'weight': 0,
                      'height': 0,
                      // ...
                    });
                    // Only navigate to MyHomePage after the above operation completes
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MyHomePage(title: 'HealthHub')));
                  }
                } catch (e) {
                  final snackBar = SnackBar(content: Text("Failed to sign up: ${e.toString()}"));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<FlSpot> _healthScores = [];
  List<FlSpot> _scoresToGraph = []; // contains the flspots from the last seven days to be graphed

  int _quoteIndex = 0;
  final List<String> _mentalHealthQuotes = [
    "“The greatest wealth is health.” – Virgil",
    "“You are worth the quiet moment. You are worth the deeper breath. You are worth the time it takes to slow down, be still, and rest.” – Morgan Harper Nichols",
    "“It’s okay to not be okay; it’s not okay to stay that way.” – Unknown",
    "“Your mental health is a priority. Your happiness is essential. Your self-care is a necessity.” – Unknown",
    "“You don’t have to be positive all the time. It’s perfectly okay to feel sad, angry, annoyed, frustrated, scared, or anxious. Having feelings doesn’t make you a negative person. It makes you human.” – Lori Deschene"
  ];
  Timer? _quoteTimer;

  @override
  void initState() {
    super.initState();
    _startQuoteTimer();
    _fetchHealthScores();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  void _startQuoteTimer() {
    _quoteTimer = Timer.periodic(const Duration(seconds: 7), (Timer timer) {
      setState(() {
        _quoteIndex = Random().nextInt(_mentalHealthQuotes.length);
      });
    });
  }

  void _fetchHealthScores() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scores')
          .orderBy('date', descending: true)
          .snapshots().listen((snapshot) {
        List<FlSpot> scores = snapshot.docs.map((doc) {
          var data = doc.data();
          DateTime date = (data['date'] as Timestamp).toDate();
          double score = data['score'];
          return FlSpot(date.millisecondsSinceEpoch.toDouble(), score);
        }).toList();

        setState(() {

          _scoresToGraph.clear(); // clear the previous data from the past seven days
          var now = DateTime.now(); // get the current date

          // search through all health scores, find the one from six days ago
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_one = now.subtract(Duration(days: 6));
            if (DateFormat.MMMd().format(day_one) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(1, scores[i].y));
              break;
            }
          }

          // search through all health scores, find the one from five days ago
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_two = now.subtract(Duration(days: 5));
            if (DateFormat.MMMd().format(day_two) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(2, scores[i].y));
              break;
            }
          }

          // search through all health scores, find the one from four days ago
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_three = now.subtract(Duration(days: 4));
            if (DateFormat.MMMd().format(day_three) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(3, scores[i].y));
              break;
            }
          }

          // search through all health scores, find the one from three days ago
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_four = now.subtract(Duration(days: 3));
            if (DateFormat.MMMd().format(day_four) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(4, scores[i].y));
              break;
            }
          }

          // search through all health scores, find the one from two days ago
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_five = now.subtract(Duration(days: 2));
            if (DateFormat.MMMd().format(day_five) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(5, scores[i].y));
              break;
            }
          }

          // search through all health scores, find the one from one day ago
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_six = now.subtract(Duration(days: 1));
            if (DateFormat.MMMd().format(day_six) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(6, scores[i].y));
              break;
            }
          }

          // search through all health scores, find the one from today
          for (int i = 0; i < scores.length; i++) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(scores[i].x.toInt());
            var day_seven = now.subtract(Duration(days: 0));
            if (DateFormat.MMMd().format(day_seven) == DateFormat.MMMd().format(date)) {
              _scoresToGraph.add(FlSpot(7, scores[i].y));
              break;
            }
          }

          _healthScores = scores; // Update the graph

        });
      });
    
    
    }
  }


  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
        ],
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 60, // Fixed height for the quote container
            child: Center(
              child: Text(
                _mentalHealthQuotes[_quoteIndex],
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: SizedBox(
                width: 400, // changed the width from 350 to 400
                height: 200,
                child: _healthScores.isNotEmpty ?
                LineChart(
                  LineChartData(
                    
                    minY: 0, // Minimum value on the y-axis
                    maxY: 100, // Assuming scores are normalized to 100
                      
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            var now = DateTime.now();
                            /* Previous getTitlesWidget:
                            final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(DateFormat.MMMd().format(date), style: const TextStyle(color: Colors.blue, fontSize: 10))
                            );
                            */

                            // switch to display x-axis labels for the date of each point
                            switch (value.toInt()) {
                              case 1:
                                var nowOneWeek = now.subtract(const Duration(days: 6));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                              case 2:
                                var nowOneWeek = now.subtract(const Duration(days: 5));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                              case 3:
                                var nowOneWeek = now.subtract(const Duration(days: 4));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                              case 4:
                                var nowOneWeek = now.subtract(const Duration(days: 3));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                              case 5:
                                var nowOneWeek = now.subtract(const Duration(days: 2));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                              case 6:
                                var nowOneWeek = now.subtract(const Duration(days: 1));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                              case 7:
                                var nowOneWeek = now.subtract(const Duration(days: 0));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(DateFormat.MMMd().format(nowOneWeek), style: const TextStyle(color: Colors.black, fontSize: 10))
                                );
                                
                            } 
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(DateFormat.MMMd().format(now), style: const TextStyle(color: Colors.black, fontSize: 10))
                            );
                            
                          }, 
                          
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: Colors.black, fontSize: 10)),
                          reservedSize: 40,
                          interval: 20, // interval on y-axis
                        ),
                      ),
                    ), 

                    gridData: const FlGridData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        /*
                        spots: [
                          const FlSpot(1, 0), 
                          const FlSpot(2, 0),
                          const FlSpot(3, 0),
                          const FlSpot(4, 0),
                          const FlSpot(5, 0),
                          const FlSpot(6, 0), 
                          const FlSpot(7, 0)
                        ], */
                        spots: _scoresToGraph, // display the spots from the past seven days
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                        
                      ),
                    ],
                  ),
                )
                    : const Text("No data available"), // Display this text when there are no scores
              ),
            ),
          ),
          FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FormPage(assessmentType: 'Anger')), // Assuming PHQ-9 as default
              );
              if (result != null) updateHealthScores(result['score'], result['assessmentType']);
            },
            label: const Text('Submit today\'s assessment'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(decoration: BoxDecoration(color: Colors.blue), child: Text('Profile')),
            ListTile(title: const Text('Profile'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()))),
            ListTile(title: const Text('Notes'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesPage()))),
            ListTile(
              title: const Text('Sign Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
            ),
          ],
        ),
      ),
    );
  }

  void updateHealthScores(double score, String assessmentType) {
    setState(() {
      var now = DateTime.now();
      _healthScores.add(FlSpot(now.millisecondsSinceEpoch.toDouble(), score));
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).collection('scores').add({
          'score': score,
          'date': now,
          'assessmentType': assessmentType, 
          'timestamp': Timestamp.fromDate(now),
        });
      }
      
      _fetchHealthScores(); // refetch the health scores and the scores to graph

    });
  }
}



class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController weightController;
  late TextEditingController heightController;
  late TextEditingController ageController;
  late TextEditingController allergiesController;
  late TextEditingController medicationsController;
  late TextEditingController medicalNeedsController;
  String? username;
  String gender = 'Select';

  @override
  void initState() {
    super.initState();
    weightController = TextEditingController();
    heightController = TextEditingController();
    ageController = TextEditingController();
    allergiesController = TextEditingController();
    medicationsController = TextEditingController();
    medicalNeedsController = TextEditingController();
    loadUserInfo();
  }

  loadUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        username = user.email;
        weightController.text = userData['weight']?.toString() ?? '';
        heightController.text = userData['height']?.toString() ?? '';
        ageController.text = userData['age']?.toString() ?? '';
        allergiesController.text = userData['allergies']?.toString() ?? '';
        medicationsController.text = userData['medications']?.toString() ?? '';
        medicalNeedsController.text =
            userData['medicalNeeds']?.toString() ?? '';
        gender = userData['gender']?.toString() ?? 'Select';
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: username == null
          ? const CircularProgressIndicator()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text('Username: $username', style: const TextStyle(fontSize: 16)),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Weight (kg)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Height (cm)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            // Increased height from 8 to 20
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Age', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            // Increased height, you can adjust this as needed
            DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Gender'),
              items: <String>['Select', 'Male', 'Female', 'Other'].map((
                  String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  gender = newValue!;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: allergiesController,
              decoration: const InputDecoration(
                  labelText: 'Allergies', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: medicationsController,
              decoration: const InputDecoration(
                  labelText: 'Medications', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: medicalNeedsController,
              decoration: const InputDecoration(labelText: 'Religious Medical Needs',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(
                    FirebaseAuth.instance.currentUser!.uid).set({
                  'weight': weightController.text.trim(),
                  'height': heightController.text.trim(),
                  'age': ageController.text.trim(),
                  'gender': gender,
                  'allergies': allergiesController.text.trim(),
                  'medications': medicationsController.text.trim(),
                  'medicalNeeds': medicalNeedsController.text.trim(),
                }, SetOptions(merge: true));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile Updated")));
              },
              child: const Text('Update Info'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  _NotesPageState createState() => _NotesPageState();
}
class _NotesPageState extends State<NotesPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final scoreController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Notes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(uid).collection('notes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No notes found'));
          }

          final notesFromLastWeek = snapshot.data!.docs.where((doc) {
            final noteDate = (doc['timestamp'] as Timestamp).toDate();
            return noteDate.isAfter(DateTime.now().subtract(const Duration(days: 7)));
          }).toList();

          double averageScore = 0;
          if (notesFromLastWeek.isNotEmpty) {
            final totalScore = notesFromLastWeek.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['score'] as double;
            }).reduce((a, b) => a + b);
            averageScore = totalScore / notesFromLastWeek.length;
          }

          return Column(
            children: [
              if (notesFromLastWeek.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Average score the last 7 days: ${averageScore.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              Expanded(
                child: ListView(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    var score = data['score'] ?? 0;
                    var emoji = getEmojiForScore(score);
                    var date = data['timestamp'] != null ? DateFormat('dd MMM yyy').format((data['timestamp'] as Timestamp).toDate()) : 'No date';
                    return Card(
                      child: ListTile(
                        title: Text(data['title']),
                        subtitle: Text(data['content']),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$score $emoji', style: const TextStyle(fontSize: 20)),
                            Text(date),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddNoteDialog(context),
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  void showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Note'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: "Title"),
                ),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(hintText: "Content"),
                ),
                TextField(
                  controller: scoreController,
                  decoration: const InputDecoration(hintText: "Score (0-10)"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                addNote();
              },
            ),
          ],
        );
      },
    );
  }

  void addNote() {
    final score = double.tryParse(scoreController.text) ?? -1;
    if (score < 0 || score > 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Score must be between 0 and 10')));
      return;
    }

    // Assume the user is logged in and we can get their UID
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').add({
      'title': titleController.text,
      'content': contentController.text,
      'score': score,
      'timestamp': Timestamp.now(),
    }).then((value) {
      Navigator.pop(context);
      // Clear text fields after adding note
      titleController.clear();
      contentController.clear();
      scoreController.clear();
    });
  }

  String getEmojiForScore(double score) {
    if (score == 10) return '⭐';
    if (score >= 7) return '😊';
    if (score >= 4) return '😐';
    if (score >= 1) return '😔';
    return '😢';
  }
}