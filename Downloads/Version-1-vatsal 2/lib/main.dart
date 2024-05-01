import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_page.dart';
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
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
            const SizedBox(height: 20),
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

enum DateRange { week, month, year }

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<FlSpot> _scoresToGraph = [];
  List<FlSpot> _healthScores = [
  ];

  DateRange _selectedRange = DateRange.week;
  int _quoteIndex = 0;
  final List<String> _mentalHealthQuotes = [
    "“The greatest wealth is health.” – Virgil",
    "“You are worth the quiet moment. You are worth the deeper breath. You are worth the time it takes to slow down, be still, and rest.” – Morgan Harper Nichols",
    "“It’s okay to not be okay; it’s not okay to stay that way.” – Unknown",
    "“Your mental health is a priority. Your happiness is essential. Your self-care is a necessity.” – Unknown",
    "“You don’t have to be positive all the time. It’s perfectly okay to feel sad, angry, annoyed, frustrated, scared, or anxious. Having feelings doesn’t make you a negative person. It makes you human.” – Lori Deschene"
  ];
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  Timer? _quoteTimer;
  StreamSubscription? _scoresSubscription;
  int daysInRange = 7;


  @override
  void initState() {
    super.initState();
    _startQuoteTimer();
    _fetchHealthScores();
    _filterScoresForSelectedRange();
  }

  @override
  void dispose() {
    _scoresSubscription?.cancel();
    _quoteTimer?.cancel();
    super.dispose();
  }


  void _startQuoteTimer() {
    _quoteTimer = Timer.periodic(const Duration(seconds: 7), (Timer timer) {
      setState(() {
        _quoteIndex = (Random().nextInt(_mentalHealthQuotes.length));
      });
    });
  }

  double averageLast7Days = 0.0;
  double averageLast30Days = 0.0;
  double averageLastYear = 0.0;

  void _fetchHealthScores() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DateTime now = DateTime.now();
      DateTime sevenDaysAgo = now.subtract(Duration(days: 7));
      DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));
      DateTime oneYearAgo = now.subtract(Duration(days: 365));

      _scoresSubscription?.cancel(); // Cancel existing subscription if any
      _scoresSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scores')
          .orderBy('date', descending: true)
          .snapshots().listen((snapshot) {
        double total7Days = 0;
        double total30Days = 0;
        double totalYear = 0;
        int count7Days = 0;
        int count30Days = 0;
        int countYear = 0;

        var fetchedScores = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime date = (data['date'] as Timestamp).toDate();
          double score = data['score'].toDouble();

          // Check and add to totals for averages
          if (date.isAfter(sevenDaysAgo)) {
            total7Days += score;
            count7Days++;
          }
          if (date.isAfter(thirtyDaysAgo)) {
            total30Days += score;
            count30Days++;
          }
          if (date.isAfter(oneYearAgo)) {
            totalYear += score;
            countYear++;
          }

          return FlSpot(date.millisecondsSinceEpoch.toDouble(), score);
        }).toList();

        if (count7Days > 0) averageLast7Days = total7Days / count7Days;
        if (count30Days > 0) averageLast30Days = total30Days / count30Days;
        if (countYear > 0) averageLastYear = totalYear / countYear;

        if (!mounted) return;
        setState(() {
          _healthScores = fetchedScores;
          _filterScoresForSelectedRange();
        });
      });
    }
  }


  void _filterScoresForSelectedRange() {
    DateTime now = DateTime.now() ;
    startDate = DateTime(now.year, now.month, now.day);
    switch (_selectedRange) {
      case DateRange.week:
        startDate = now.subtract(Duration(days: now.weekday + 5)) ;
        daysInRange = 7;
        break;
      case DateRange.month:
        startDate = DateTime(now.year, now.month, 1);
        daysInRange = DateUtils.getDaysInMonth(now.year, now.month);
        break;
      case DateRange.year:
        startDate = DateTime(now.year, 1, 1);
        daysInRange = DateTime(now.year + 1, 1, 1).difference(startDate).inDays;
        break;
      default:
        startDate = now;
        daysInRange = 1;
        break;
    }
    updateGraphData();
    setState(() {});
  }


  void updateGraphData() {
    _scoresToGraph = _healthScores.where((score) {
      DateTime scoreDate = DateTime.fromMillisecondsSinceEpoch(score.x.toInt());

      scoreDate = DateTime(scoreDate.year, scoreDate.month, scoreDate.day);
      return scoreDate.isAfter(startDate) && scoreDate.isBefore(endDate.add(Duration(days: 1)));
    }).map((score) {
      DateTime scoreDate = DateTime.fromMillisecondsSinceEpoch(score.x.toInt());

      int daysSinceStart = scoreDate.difference(startDate).inDays;
      return FlSpot(daysSinceStart.toDouble(), score.y);
    }).toList();
    setState(() {});
  }

  Color _getColorForAverageScore(double averageScore) {
    if (averageScore >= 70) {
      return Colors.green;
    } else if (averageScore >= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
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
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ProfilePage())),
          ),
        ],
      ),
      body: SingleChildScrollView( // Wrap your column in a SingleChildScrollView
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 40,
              child: Center(
                child: Text(
                  _mentalHealthQuotes[_quoteIndex],
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            DropdownButton<DateRange>(
              value: _selectedRange,
              onChanged: (DateRange? newValue) {
                setState(() {
                  _selectedRange = newValue!;
                  _filterScoresForSelectedRange();
                });
              },
              items: DateRange.values.map((DateRange classType) {
                return DropdownMenuItem<DateRange>(
                  value: classType,
                  child: Text(classType.toString().split('.').last),
                );
              }).toList(),
            ),
            Text("Quick Stats:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Average last 7 days: ${averageLast7Days.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getColorForAverageScore(averageLast7Days),
              ),
            ),
            Text(
              "Average last 30 days: ${averageLast30Days.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getColorForAverageScore(averageLast30Days),
              ),
            ),
            Text(
              "Average last year: ${averageLastYear.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getColorForAverageScore(averageLastYear),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.8, // 80% of the screen width
              height: 600, // Fixed height to make the graph horizontally long
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100), // Adjust horizontal padding if needed
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: daysInRange.toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _scoresToGraph,
                        isCurved: false,
                        color: Colors.blue,
                        barWidth: 5,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      )
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25,
                          interval: _selectedRange == DateRange.week ? 1 : _selectedRange == DateRange.month ? 3 : 30,
                          getTitlesWidget: (value, meta) {
                            DateTime labelDate = startDate.add(Duration(days: value.toInt() + (_selectedRange == DateRange.week ? 1 : 0)));
                            String formattedDate = DateFormat.MMMd().format(labelDate);
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(formattedDate, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FormPage(assessmentType: 'Anxiety')),
                  );
                  if (result != null && result is Map) {
                    double score = result['score'] ?? 0.0;
                    DateTime date = result['date'] ?? DateTime.now();
                    updateHealthScores(score, 'Anxiety', date);
                  }
                },
                label: const Text('Submit today\'s assessment'),
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(decoration: BoxDecoration(color: Colors.blue),
                child: Text('Profile')),
            ListTile(title: const Text('Profile'),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const ProfilePage()))),
            ListTile(title: const Text('Notes'),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const NotesPage()))),
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



  void updateHealthScores(double score, String assessmentType, DateTime assessmentDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var scoresRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('scores');

      var dayStart = DateTime(assessmentDate.year, assessmentDate.month, assessmentDate.day);
      var dayEnd = DateTime(assessmentDate.year, assessmentDate.month, assessmentDate.day + 1);


      print("Day start: $dayStart, Day end: $dayEnd");


      var querySnapshot = await scoresRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .where('date', isLessThan: Timestamp.fromDate(dayEnd))
          .get();


      print("Scores found to delete: ${querySnapshot.docs.length}");


      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(scoresRef.doc(doc.id));
      }


      await batch.commit().then((_) {
        print("Successfully deleted scores for the day.");
      }).catchError((error) {
        print("Failed to delete scores: $error");
      });


      scoresRef.add({
        'score': score,
        'date': Timestamp.fromDate(assessmentDate), // Use the specific assessment date
        'assessmentType': assessmentType,
        'timestamp': Timestamp.now(), // Use current time for exact timestamp tracking
      }).then((_) {
        print("New score added successfully.");
      }).catchError((error) {
        print("Error adding score: $error");
      });


      _fetchHealthScores();
    }
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
            ElevatedButton(
                  onPressed: _exportProfileAsPDF, // Call the method to generate PDF
                  child: Text('Export as PDF'),
                ),
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
  Future<void> _exportProfileAsPDF() async {
    final pdf = pw.Document();
    print("here");
    pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('User Profile', style: pw.TextStyle(fontSize: 24)),
              pw.Text('Username: $username'),
              pw.Text('Weight: ${weightController.text} kg'),
              pw.Text('Height: ${heightController.text} cm'),
              pw.Text('Age: ${ageController.text}'),
              pw.Text('Gender: $gender'),
              pw.Text('Allergies: ${allergiesController.text}'),
              pw.Text('Medications: ${medicationsController.text}'),
              pw.Text('Religious Medical Needs: ${medicalNeedsController.text}'),
            ],
          ),
        );
      },
    ),
  );
    // Query scores collection for the past seven days
  final User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scores')
        .where('timestamp', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 7)))
        .get();

    // Calculate average score
    double totalScore = 0;
    int numScores = snapshot.docs.length;
    for (final doc in snapshot.docs) {
      totalScore += doc['score'];
    }
    double averageScore = numScores > 0 ? totalScore / numScores : 0;

    // Add scores information to PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Scores for the Past Seven Days', style: pw.TextStyle(fontSize: 24)),
                for (final doc in snapshot.docs)
                   pw.Text('${DateFormat.yMd().format(doc['date'].toDate())}: ${doc['score']}'),
                pw.Text('Average Score: $averageScore'),
              ],
            ),
          );
        },
      ),
    );
  }

    final String dir = (await getDownloadsDirectory())!.path;
    final String path = '$dir/user_profile.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());

    // Show a dialog or snackbar to inform the user that the PDF is saved
    try {
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile exported as PDF. File saved at: $path'),
        ),
      );
    } catch (e) {
      print('Error saving PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF')),
      );
}
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