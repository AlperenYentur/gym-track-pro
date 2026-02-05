// Bu dosya sabit hareket listesini tutar.
// İleride burayı da veritabanından çekebiliriz ama şimdilik statik olsun.

class ExerciseData {
  static final Map<String, List<String>> exercises = {
    'Göğüs': [
      'Bench Press',
      'Incline Bench Press',
      'Dumbbell Fly',
      'Cable Crossover',
      'Push Up',
      'Chest Press Machine'
    ],
    'Sırt': [
      'Lat Pulldown',
      'Seated Cable Row',
      'Barbell Row',
      'Deadlift',
      'Pull Up (Barfiks)',
      'T-Bar Row'
    ],
    'Omuz': [
      'Overhead Press',
      'Lateral Raise',
      'Front Raise',
      'Face Pull',
      'Shrugs',
      'Arnold Press'
    ],
    'Bacak': [
      'Squat',
      'Leg Press',
      'Leg Extension',
      'Leg Curl',
      'Lunges',
      'Calf Raise'
    ],
    'Ön Kol (Biceps)': [
      'Barbell Curl',
      'Dumbbell Curl',
      'Hammer Curl',
      'Preacher Curl',
      'Concentration Curl'
    ],
    'Arka Kol (Triceps)': [
      'Triceps Pushdown',
      'Skull Crusher',
      'Dips',
      'Overhead Extension',
      'Kickback'
    ],
    'Karın (Abs)': [
      'Plank',
      'Crunches',
      'Leg Raise',
      'Russian Twist',
      'Mountain Climber'
    ]
  };
}