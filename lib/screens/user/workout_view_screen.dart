import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:line_icons/line_icons.dart';

class WorkoutViewScreen extends StatefulWidget {
  final String workoutProgramJson;
  final String memberName;

  const WorkoutViewScreen({
    super.key,
    required this.workoutProgramJson,
    required this.memberName,
  });

  @override
  State<WorkoutViewScreen> createState() => _WorkoutViewScreenState();
}

class _WorkoutViewScreenState extends State<WorkoutViewScreen> {
  List<dynamic> _program = [];

  // Hareketlerin tamamlanma durumunu tutan map
  // Anahtar: "GünIndex-HareketIndex", Değer: true/false
  final Map<String, bool> _completionStatus = {};

  // Üyenin girdiği notları tutan map
  // Anahtar: "GünIndex-HareketIndex", Değer: "Girilen not"
  final Map<String, String> _userNotes = {};

  @override
  void initState() {
    super.initState();
    _parseProgram();
  }

  void _parseProgram() {
    if (widget.workoutProgramJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.workoutProgramJson);
        if (decoded is List) {
          setState(() {
            _program = decoded;
          });
        }
      } catch (e) {
        debugPrint("JSON Hatası: $e");
      }
    }
  }

  // Not Ekleme Penceresi
  void _showNoteDialog(String key, String exerciseName) {
    TextEditingController noteCtrl =
        TextEditingController(text: _userNotes[key] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$exerciseName Notu"),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
            hintText: "Örn: 3. sette 60kg denedim...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              setState(() {
                if (noteCtrl.text.trim().isEmpty) {
                  _userNotes.remove(key);
                } else {
                  _userNotes[key] = noteCtrl.text.trim();
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Antrenman Programım",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _program.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _program.length,
              itemBuilder: (context, dayIndex) {
                final dayData = _program[dayIndex];
                final String dayName = dayData['day'] ?? 'Gün ${dayIndex + 1}';
                final List exercises = dayData['exercises'] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: dayIndex == 0, // İlk gün açık gelsin
                      title: Text(
                        dayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      children: exercises.asMap().entries.map((entry) {
                        int exIndex = entry.key;
                        Map exercise = entry.value;

                        String name = exercise['name'];
                        String sets = exercise['sets'];
                        String reps = exercise['reps'];
                        String trainerNote = exercise['note'] ?? "";

                        // Unique Key oluşturuyoruz
                        String key = "$dayIndex-$exIndex";
                        bool isCompleted = _completionStatus[key] ?? false;
                        String? myNote = _userNotes[key];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Colors.grey.shade100)),
                            color: isCompleted ? Colors.green.shade50 : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _completionStatus[key] = !isCompleted;
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.white,
                                      border: Border.all(
                                        color: isCompleted
                                            ? Colors.green
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 20,
                                      color: isCompleted
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isCompleted
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text("$sets Set x $reps Tekrar",
                                    style:
                                        const TextStyle(color: Colors.black54)),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit_note,
                                      color: myNote != null
                                          ? Colors.blue
                                          : Colors.grey),
                                  onPressed: () => _showNoteDialog(key, name),
                                ),
                              ),

                              // HOCA NOTU VARSA
                              if (trainerNote.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(
                                      left: 56, bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: Colors.orange.shade200)),
                                  child: Text(
                                    "Hoca Notu: $trainerNote",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade800),
                                  ),
                                ),

                              // ÜYE KENDİ NOTU VARSA (YENİ EKLENDİ)
                              if (myNote != null)
                                Container(
                                  width: double.infinity,
                                  margin:
                                      const EdgeInsets.only(left: 56, top: 4),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.blue.shade200)),
                                  child: Text(
                                    "Senin Notun: $myNote",
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade900,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LineIcons.dumbbell, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "Henüz bir programın yok.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text("Eğitmeninden program talep edebilirsin.",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
