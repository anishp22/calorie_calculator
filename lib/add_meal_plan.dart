import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'main.dart';
import 'meal_plan.dart';
import 'package:intl/intl.dart';

// page for adding meal plan
class AddMealPlanPage extends StatefulWidget {
  final MealPlan? mealPlan;
  const AddMealPlanPage({Key? key, this.mealPlan}) : super(key: key);

  @override
  _AddMealPlanPageState createState() => _AddMealPlanPageState();
}

class _AddMealPlanPageState extends State<AddMealPlanPage> {
  late DateTime selectedDate;
  late int? targetCalories;
  TextEditingController targetCaloriesController = TextEditingController();
  Map<String, int> selectedFoodCounts = {};

  @override
  void initState() {
    super.initState();

    targetCaloriesController = TextEditingController(
        text: widget.mealPlan?.targetCalories?.toString() ?? '0'
    );
    foodMap.forEach((key, value) {
      selectedFoodCounts[key] = 0;
    });

    if (widget.mealPlan != null) {
      // get the date from the mealplan
      selectedDate = DateFormat('yyyy-MM-dd').parse(widget.mealPlan!.date);
      targetCalories = widget.mealPlan!.targetCalories;

      var foods = widget.mealPlan!.plan.split(', ');
      for (var food in foods) {
        var parts = food.split(':');
        if (parts.length == 2) {
          selectedFoodCounts[parts[0]] = int.parse(parts[1]);
        }
      }
    } else {
      selectedDate = DateTime.now();
      targetCalories = 0;
    }
  }

  // used to select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // counts up the total calories based off teh food the user has added
  int _calculateTotalCalories() {
    int total = 0;
    selectedFoodCounts.forEach((food, count) {
      int caloriesPerItem = foodMap[food] ?? 0;
      total += caloriesPerItem * count;
    });
    return total;
  }

  // saves the mealplan
  Future<void> _saveMealPlan() async {
    if (selectedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }

    // checks if the user has set a calorie target for the day
    if (targetCalories == null) {
      _showSnackBar('Target calories must be set.');
      return;
    }

    // lets the user know that they are going over the calories
    int totalCalories = _calculateTotalCalories();
    if (totalCalories > targetCalories!) {
      _showSnackBar('Food items go over the calories.');
      return;
    }

    String foodCounts = selectedFoodCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => "${entry.key}:${entry.value}")
        .join(', ');

    final plan = MealPlan(
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      targetCalories: targetCalories!,
      plan: foodCounts,
    );

    final dbHelper = DatabaseHelper();
    await dbHelper.insertMealPlan(plan);
    Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _changeFoodCount(String food, int change) {
    setState(() {
      selectedFoodCounts[food] =
          (selectedFoodCounts[food]! + change).clamp(0, 99);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Meal Plan')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text("Select Date: ${DateFormat('yyyy-MM-dd').format(
                  selectedDate)}"),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 200, // Adjust the width as needed
                child: TextField(
                  controller: targetCaloriesController,
                  decoration: InputDecoration(
                    labelText: "Target Calories",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    targetCalories = int.tryParse(value);
                  },
                ),
              ),
            ),
            // Display current total calories
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Current Calories: ${_calculateTotalCalories()}',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ...selectedFoodCounts.keys.map((food) {
              return ListTile(
                title: Text(food),
                subtitle: Text("${foodMap[food]} calories"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => _changeFoodCount(food, -1),
                    ),
                    Text('${selectedFoodCounts[food]}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _changeFoodCount(food, 1),
                    ),
                  ],
                ),
              );
            }).toList(),
            ElevatedButton(
              onPressed: _saveMealPlan,
              child: const Text('Save Meal Plan'),
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFF6B9080),
              ),
            ),
          ],
        ),
      ),
    );
  }
}