class MealPlan {
  final String date;
  final int targetCalories;
  final String plan;

  MealPlan({required this.date, required this.targetCalories, required this.plan});

  // gets mealplan info from DB
  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      date: map['date'],
      targetCalories: map['target_calories'],
      plan: map['meal_plan'],
    );
  }

  // makes a map to add mealplan data to the database
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'target_calories': targetCalories,
      'meal_plan': plan,
    };
  }

}