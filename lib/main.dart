import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'meal_plan.dart';
import 'package:intl/intl.dart';
import 'add_meal_plan.dart';

// 20 hardcoded food items
final Map<String, int> foodMap = {
  'Apple': 95,
  'Banana': 105,
  'Orange': 62,
  'Eggs': 78,
  'Chicken Breast': 165,
  'Greek Yogurt': 100,
  'Brown Rice': 218,
  'Quinoa': 222,
  'Whole Wheat Bread Slice': 69,
  'Avocado': 322,
  'Milk': 122,
  'Oatmeal': 159,
  'Pasta': 220,
  'Potato': 161,
  'Peanut Butter': 94,
  'Broccoli': 55,
  'Cottage Cheese': 222,
  'Hummus(1tbsp)': 25,
  'Carrots': 52,
  'Olive Oil': 119,
};


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // adds food data into the food_calories
  final dbHelper = DatabaseHelper();
  await dbHelper.insertFoodData(foodMap);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myCalorieCalculator',
      theme: ThemeData(
        primaryColor: const Color(0xFF6B9080),
        hintColor: const Color(0xFFA4C3B2),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFCCE3DE)),
        scaffoldBackgroundColor: const Color(0xFFEAF4F4),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF6B9080),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: const Color(0xFFCCE3DE),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: const Color(0xFFA4C3B2),
          ),
        ),
      ),
      home: const MyHomePage(title: 'myCalorieCalculator'),
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

  List<MealPlan> mealPlans = [];
  DateTime? filterDate;
  TextEditingController dateController = TextEditingController();

  @override
  void initState(){
    super.initState();
    loadMealPlans();
  }

  // gets the meal plans based of the date entered by the user
  Future<void> _pickFilterDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: filterDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        filterDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        loadMealPlans();
      });
    }
  }

  // calls delete method to remove a meal plan
  void _deleteMealPlan(String date) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteMealPlan(date);

    // refresh the meal plans
    loadMealPlans();
  }
  // calls load meal plan method from the database
  void loadMealPlans() async {
    final dbHelper = DatabaseHelper();
    var allPlans = await dbHelper.getAllMealPlans();

    // Filter the meal plans if there is a filter date set
    setState(() {
      if (filterDate != null) {
        mealPlans = allPlans.where((plan) {
          return DateFormat('yyyy-MM-dd').parse(plan.date) == filterDate;
        }).toList();
      } else {
        mealPlans = allPlans;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: "Search for Date here",
                suffixIcon: filterDate != null
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      filterDate = null;
                      dateController.clear();
                      loadMealPlans();
                    });
                  },
                )
                    : Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _pickFilterDate(context),
            ),
          ),
          Expanded(
            child: mealPlans.isEmpty
                ? Center(child: Text("There are no meal plans created."))
                : ListView.builder(
              itemCount: mealPlans.length,
              itemBuilder: (context, index) {
                final plan = mealPlans[index];
                return Card(
                  child: ListTile(
                    title: Text("Date: ${plan.date}"),
                    subtitle: Text("Target Calories: ${plan.targetCalories}"),
                    trailing: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => _deleteMealPlan(plan.date),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMealPlanPage(mealPlan: mealPlans[index]),
                        ),
                      ).then((_) => loadMealPlans());
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddMealPlanPage()),
        ).then((_) => loadMealPlans()),
        tooltip: 'Enter Meal Plan',
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF6B9080),
      ),
    );
  }
}


