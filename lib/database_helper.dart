  import 'package:sqflite/sqflite.dart';
  import 'package:path/path.dart';
  import 'meal_plan.dart';

  class DatabaseHelper {
    static Future<Database> getDatabase() async {
      final dbPath = await getDatabasesPath();

      return openDatabase(
        join(dbPath, 'calorie_calculator.db'),
        // creates a table for the foods calories and a table to store the meal plans
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE foodCalories(food TEXT PRIMARY KEY, calories INTEGER);',
          );
          await db.execute(
            'CREATE TABLE mealPlan(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, target_calories INTEGER, meal_plan TEXT);',
          );
        },
        version: 1,
      );
    }

    // adds the list of foods and their calories into the db
    Future<void> insertFoodData(Map<String, int> foodData) async {
      final db = await getDatabase();
      for (var food in foodData.entries) {
        try {
          await db.insert(
            'foodCalories',
            {'food': food.key, 'calories': food.value},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (e) {
          print(e);
        }
      }
    }

    Future<void> insertMealPlan(MealPlan plan) async {
      final db = await getDatabase();

      // checks if a meal plan exists for the date the user has selected
      var existingPlan = await db.query(
        'mealPlan',
        where: 'date = ?',
        whereArgs: [plan.date],
      );

      // if statement to update an existing meal plan and if there isn't one, it will create a new plan
      if (existingPlan.isNotEmpty) {
        await db.update(
          'mealPlan',
          plan.toMap(),
          where: 'date = ?',
          whereArgs: [plan.date],
        );
      } else {
        await db.insert(
          'mealPlan',
          plan.toMap(),
        );
      }
    }

    // query for all the mealplans saved
    Future<List<MealPlan>> getAllMealPlans() async {
      final db = await getDatabase();
      final List<Map<String, dynamic>> maps = await db.query('mealPlan');

      return List.generate(maps.length, (i){
        return MealPlan.fromMap(maps[i]);
      });
    }

    // function to remove a meal plan from the database
    Future<void> deleteMealPlan(String date) async {
      final db = await getDatabase();
      await db.delete(
        'mealPlan',
        where: 'date = ?',
        whereArgs: [date],
      );
    }

  }