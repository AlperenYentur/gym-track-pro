import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:line_icons/line_icons.dart';
import '../../services/database_service.dart';
import '../../models/member_model.dart';

class WorkoutEditorScreen extends StatefulWidget {
  final MemberModel member;
  const WorkoutEditorScreen({super.key, required this.member});

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  List<Map<String, dynamic>> _program = [];
  final DatabaseService _db = DatabaseService();
  String _initialJson = "[]";

  final Map<String, List<String>> _exerciseDatabase = {
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
      'Pull Up',
      'Barbell Row',
      'Seated Cable Row',
      'Deadlift',
      'Face Pull'
    ],
    'Omuz': [
      'Overhead Press',
      'Lateral Raise',
      'Front Raise',
      'Rear Delt Fly',
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
    'Ön Kol': ['Barbell Curl', 'Dumbbell Curl', 'Hammer Curl', 'Preacher Curl'],
    'Arka Kol': [
      'Triceps Pushdown',
      'Skull Crusher',
      'Dips',
      'Overhead Extension',
      'Kickback'
    ],
    'Karın': ['Crunch', 'Plank', 'Leg Raise', 'Russian Twist'],
    'Kardiyo': ['Koşu Bandı', 'Bisiklet', 'Eliptik', 'Kürek'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.member.workoutProgram != null &&
        widget.member.workoutProgram!.isNotEmpty) {
      try {
        if (widget.member.workoutProgram!.startsWith("[")) {
          _initialJson = widget.member.workoutProgram!;
          List<dynamic> decoded = jsonDecode(_initialJson);
          _program = decoded.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint("Format hatası: $e");
      }
    }
  }

  // --- HAREKET SIRALAMA FONKSİYONLARI ---
  void _moveExerciseUp(int dayIndex, int exIndex) {
    if (exIndex > 0) {
      setState(() {
        final exercises = _program[dayIndex]['exercises'] as List;
        final item = exercises.removeAt(exIndex);
        exercises.insert(exIndex - 1, item);
      });
    }
  }

  void _moveExerciseDown(int dayIndex, int exIndex) {
    final exercises = _program[dayIndex]['exercises'] as List;
    if (exIndex < exercises.length - 1) {
      setState(() {
        final item = exercises.removeAt(exIndex);
        exercises.insert(exIndex + 1, item);
      });
    }
  }
  // ---------------------------------------

  Future<bool> _onWillPop() async {
    String currentJson = jsonEncode(_program);
    if (currentJson == _initialJson ||
        (_initialJson == "[]" && _program.isEmpty)) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ Kaydedilmemiş Değişiklikler"),
        content: const Text(
            "Yaptığınız değişiklikleri kaydetmeden çıkmak üzeresiniz. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Evet, Çık",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _saveProgram() {
    if (_program.isEmpty) {
      _db.assignWorkoutProgram(widget.member.id, "");
      _initialJson = "[]";
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Program temizlendi."), backgroundColor: Colors.grey));
      return;
    }

    bool hasAnyExercise =
        _program.any((day) => (day['exercises'] as List).isNotEmpty);
    if (!hasAnyExercise) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Lütfen günlerin içine en az bir hareket ekleyin! ⚠️"),
          backgroundColor: Colors.red));
      return;
    }

    String currentJson = jsonEncode(_program);
    if (currentJson == _initialJson) {
      Navigator.pop(context);
      return;
    }

    _db.assignWorkoutProgram(widget.member.id, currentJson);
    _initialJson = currentJson;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Program kaydedildi! ✅"), backgroundColor: Colors.green));
  }

  void _addDay() {
    TextEditingController dayTitleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni Gün Ekle"),
        content: TextField(
          controller: dayTitleController,
          decoration: const InputDecoration(
              hintText: "Örn: 1. Gün - İtiş", filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              if (dayTitleController.text.trim().isNotEmpty) {
                setState(() {
                  _program.add(
                      {'dayName': dayTitleController.text, 'exercises': []});
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("EKLE"),
          )
        ],
      ),
    );
  }

  // --- HAREKET SEÇİCİ (Tablo Görünümü - Düzeltildi) ---
  void _showExercisePicker(int dayIndex) {
    String selectedCategory = _exerciseDatabase.keys.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Hareket Seçimi",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCustomExerciseDialog(dayIndex);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Liste Dışı Ekle"),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- DEĞİŞİKLİK BURADA: Wrap Kullanıldı ---
                  // Artık sığmayanlar alt satıra geçer, hepsi görünür.
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 8.0, // Yan yana boşluk
                      runSpacing: 0.0, // Alt satır boşluğu
                      children: _exerciseDatabase.keys.map((category) {
                        bool isSelected = category == selectedCategory;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: Colors.black,
                          labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black),
                          onSelected: (val) {
                            setModalState(() => selectedCategory = category);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  // ------------------------------------------

                  const Divider(height: 20),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _exerciseDatabase[selectedCategory]!.length,
                      itemBuilder: (context, index) {
                        final exerciseName =
                            _exerciseDatabase[selectedCategory]![index];
                        return ListTile(
                          title: Text(exerciseName),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showScrollPicker(context, dayIndex, exerciseName);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showCustomExerciseDialog(int dayIndex) {
    TextEditingController customNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Özel Hareket Ekle"),
        content: TextField(
          controller: customNameController,
          decoration: const InputDecoration(
              hintText: "Hareket Adı (Örn: Landmine Press)", filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white),
            onPressed: () {
              if (customNameController.text.isNotEmpty) {
                Navigator.pop(ctx);
                _showScrollPicker(context, dayIndex, customNameController.text);
              }
            },
            child: const Text("DEVAM ET"),
          )
        ],
      ),
    );
  }

  void _showScrollPicker(
      BuildContext parentContext, int dayIndex, String exerciseName) {
    int selectedSets = 4;
    int selectedReps = 12;
    TextEditingController noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(exerciseName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text("Set ve Tekrar Sayısını Seçin",
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text("SET",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController:
                                    FixedExtentScrollController(initialItem: 3),
                                onSelectedItemChanged: (val) =>
                                    selectedSets = val + 1,
                                children: List.generate(
                                    10,
                                    (index) => Center(
                                        child: Text("${index + 1}",
                                            style: const TextStyle(
                                                fontSize: 22)))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("TEKRAR",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(
                                    initialItem: 11),
                                onSelectedItemChanged: (val) =>
                                    selectedReps = val + 1,
                                children: List.generate(
                                    50,
                                    (index) => Center(
                                        child: Text("${index + 1}",
                                            style: const TextStyle(
                                                fontSize: 22)))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      hintText: "Özel not ekle (Örn: Drop set, yavaş yap...)",
                      prefixIcon: Icon(LineIcons.stickyNote),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() {
                        List<dynamic> exercises =
                            _program[dayIndex]['exercises'];
                        exercises.add({
                          'name': exerciseName,
                          'sets': selectedSets.toString(),
                          'reps': selectedReps.toString(),
                          'note': noteController.text,
                        });
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text("PROGRAMA EKLE"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.member.name} Programı"),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: "Kaydet",
              onPressed: _saveProgram,
            )
          ],
        ),
        body: _program.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LineIcons.dumbbell,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text("Henüz bir program oluşturulmadı."),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: _addDay,
                      icon: const Icon(Icons.add),
                      label: const Text("İlk Günü Ekle"),
                    )
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _program.length,
                itemBuilder: (context, index) {
                  final dayData = _program[index];
                  final List exercises = dayData['exercises'];

                  return Card(
                    key: ValueKey("Day_$index"),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300)),
                    child: ExpansionTile(
                      title: Text(dayData['dayName'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text("${exercises.length} Hareket"),
                      initiallyExpanded: true,
                      shape: const Border(),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _program.removeAt(index));
                        },
                      ),
                      children: [
                        if (exercises.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("Henüz hareket eklenmedi.")),

                        // YENİ: STANDART LISTVIEW (SÜRÜKLE BIRAK YOK)
                        if (exercises.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exercises.length,
                            itemBuilder: (context, exIndex) {
                              final ex = exercises[exIndex];
                              final String note = ex['note'] ?? "";

                              // İlk ve Son eleman kontrolü
                              final bool isFirst = exIndex == 0;
                              final bool isLast =
                                  exIndex == exercises.length - 1;

                              return Container(
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFEEEEEE)))),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(16, 4, 8, 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(LineIcons.dumbbell,
                                        size: 20),
                                  ),
                                  title: Text(ex['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "${ex['sets']} Set x ${ex['reps']} Tekrar"),
                                      if (note.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Text("📝 $note",
                                              style: TextStyle(
                                                  color: Colors.orange[800],
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic)),
                                        )
                                    ],
                                  ),
                                  // BUTONLAR GRUBU (Sağa Dayalı)
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // YUKARI OKU (İlk elemansa gösterme)
                                      if (!isFirst)
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward,
                                              size: 20, color: Colors.blue),
                                          constraints:
                                              const BoxConstraints(), // Sıkışık düzen
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          onPressed: () =>
                                              _moveExerciseUp(index, exIndex),
                                        ),

                                      // AŞAĞI OKU (Son elemansa gösterme)
                                      if (!isLast)
                                        IconButton(
                                          icon: const Icon(Icons.arrow_downward,
                                              size: 20, color: Colors.blue),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          onPressed: () =>
                                              _moveExerciseDown(index, exIndex),
                                        )
                                      else
                                        // Hizalama bozulmasın diye boşluk bırakılabilir, ama şu an gerek yok
                                        const SizedBox.shrink(),

                                      const SizedBox(width: 8), // Ara boşluk

                                      // SİLME BUTONU
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            size: 20, color: Colors.red),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        onPressed: () {
                                          setState(() {
                                            exercises.removeAt(exIndex);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton.icon(
                            onPressed: () => _showExercisePicker(index),
                            icon: const Icon(Icons.add_circle,
                                color: Colors.black),
                            label: const Text("Bu Güne Hareket Ekle",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addDay,
          backgroundColor: Colors.black,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Yeni Gün Ekle",
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
