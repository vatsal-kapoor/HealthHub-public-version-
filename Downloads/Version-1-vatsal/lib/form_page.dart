import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FormPage extends StatefulWidget {
  final String assessmentType;

  FormPage({Key? key, required this.assessmentType}) : super(key: key);

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  late List<SurveyQuestion> questions;
  DateTime? selectedDate;
  late String selectedAssessmentType = 'Anxiety'; // Default value

  @override
  void initState() {
    super.initState();
    questions = getQuestionsForType(widget.assessmentType);
    // Trigger date selection immediately
    WidgetsBinding.instance!.addPostFrameCallback((_) => _promptForDate());
  }

  Future<void> _promptForDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  List<SurveyQuestion> getQuestionsForType(String type) {
    // Example simplified, adjust your questions accordingly
    switch (type) {
      case 'Anxiety':
        return [
          SurveyQuestion('Little interest or pleasure in doing things', 3),
          SurveyQuestion('Feeling down, depressed, or hopeless', 3),
          SurveyQuestion('Trouble falling asleep, staying asleep, or sleeping too much', 3),
          SurveyQuestion('Feeling tired or having little energy', 3),
          SurveyQuestion('Poor appetite or overeating', 3),
          SurveyQuestion('Feeling bad about yourself - or that you’re a failure or have let yourself or your family down', 3),
          SurveyQuestion('Trouble concentrating on things, such as reading the newspaper or watching television', 3),
          SurveyQuestion('Moving or speaking so slowly that other people could have noticed. Or, the opposite - being so fidgety or restless that you have been moving around a lot more than usual', 3),
          SurveyQuestion('Thoughts that you would be better off dead or of hurting yourself in some way', 3),
        ];
      case 'Depression':
        return [
          SurveyQuestion('Feeling down, depressed, or hopeless', 3),
          SurveyQuestion('Little interest or pleasure in doing things', 3),
          SurveyQuestion('Trouble falling asleep, staying asleep, or sleeping too much', 3),
          SurveyQuestion('Feeling tired or having little energy', 3),
          SurveyQuestion('Poor appetite or overeating', 3),
          SurveyQuestion('Feeling bad about yourself - or that you’re a failure or have let yourself or your family down', 3),
          SurveyQuestion('Trouble concentrating on things, such as reading the newspaper or watching television', 3),
          SurveyQuestion('Moving or speaking so slowly that other people could have noticed. Or, the opposite - being so fidgety or restless that you have been moving around a lot more than usual', 3),
          SurveyQuestion('Thoughts that you would be better off dead or of hurting yourself in some way', 3),
        ];
      case 'Anger':
        return [
          SurveyQuestion('Feeling irritable or easily annoyed', 3),
          SurveyQuestion('Feeling angry, resentful, or bitter', 3),
          SurveyQuestion('Having frequent arguments or conflicts', 3),
          SurveyQuestion('Getting angry in response to frustration or inconvenience', 3),
          SurveyQuestion('Expressing anger in an aggressive or violent manner', 3),
          SurveyQuestion('Experiencing physical symptoms of anger, such as increased heart rate or tension', 3),
          SurveyQuestion('Finding it difficult to control or manage anger', 3),
        ];
      case 'Happiness':
        return [
          SurveyQuestion('Feeling joyful or content', 3),
          SurveyQuestion('Experiencing moments of pleasure or satisfaction', 3),
          SurveyQuestion('Having a positive outlook on life', 3),
          SurveyQuestion('Feeling grateful or appreciative', 3),
          SurveyQuestion('Engaging in activities that bring happiness or fulfillment', 3),
          SurveyQuestion('Maintaining positive relationships with others', 3),
          SurveyQuestion('Finding meaning or purpose in daily life', 3),
        ];
      // Add cases for other assessment types here
      default:
        return [];
    }
  }

  @override
Widget build(BuildContext context) {
  if (selectedDate == null) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Date for Assessment'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  return Scaffold(
    appBar: AppBar(
      title: Text('Assessment: $selectedAssessmentType'),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () => _promptForDate(),
          tooltip: 'Change Date',
        )
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<String>(
            value: selectedAssessmentType,
            onChanged: (String? newValue) {
              setState(() {
                selectedAssessmentType = newValue!;
                questions = getQuestionsForType(selectedAssessmentType);
              });
            },
            items: ['Anxiety', 'Depression', 'Anger', 'Happiness', 'Other']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return ListTile(
                title: Text(question.questionText),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(question.maxScore, (i) {
                    int value = i + 1;
                    return IconButton(
                      icon: Icon(
                        value <= question.currentScore ? Icons.star : Icons.star_border,
                        color: value <= question.currentScore ? Colors.yellow : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          question.currentScore = value;
                        });
                      },
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _submitAssessment,
      child: Icon(Icons.check),
      tooltip: 'Submit Assessment',
    ),
  );
}


  void _submitAssessment() {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a date for the assessment.")),
      );
      return;
    }

    double totalScore = questions.fold(0, (sum, question) => sum + question.currentScore);
    double normalizedScore = 100 - (totalScore / (questions.length * 3)) * 100;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).collection('scores').add({
        'score': normalizedScore,
        'date': selectedDate,
        'timestamp': Timestamp.fromDate(selectedDate!),
        'assessmentType': selectedAssessmentType, // Add assessment type here
      }).then((value) => Navigator.pop(context, normalizedScore));
    }
  }
}

class SurveyQuestion {
  String questionText;
  int maxScore;
  int currentScore = 0;

  SurveyQuestion(this.questionText, this.maxScore);
}
