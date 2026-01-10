import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import '../../models/measurement_model.dart';
import '../../services/database_service.dart';

class MeasurementScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MeasurementScreen(
      {super.key, required this.memberId, required this.memberName});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends State<MeasurementScreen> {
  final DatabaseService _db = DatabaseService();

  // Hangi grafiğin gösterileceği (Varsayılan: Kilo)
  String _selectedMetric = "Kilo";
  String _currentUnit = "kg";

  // --- DEĞER CONTROLLERLARI ---
  final _weightCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _legCtrl = TextEditingController();

  // --- ÖZEL GİRİŞ CONTROLLERLARI ---
  final _customNameCtrl = TextEditingController();
  final _customValueCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();

  // PENCEREYİ AÇMA
  void _showAddDialog(List<MeasurementModel> history) {
    // Temizlik
    _weightCtrl.clear();
    _fatCtrl.clear();
    _waistCtrl.clear();
    _chestCtrl.clear();
    _armCtrl.clear();
    _legCtrl.clear();
    _customNameCtrl.clear();
    _customValueCtrl.clear();
    _customUnitCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ölçüm Ekle"),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Standart Ölçümler:",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 10),

              // BİRİMLER SABİT (STRING)
              _inputRow("Kilo", _weightCtrl, "kg"),
              _inputRow("Yağ Oranı", _fatCtrl, "%"),
              _inputRow("Bel", _waistCtrl, "cm"),
              _inputRow("Göğüs", _chestCtrl, "cm"),
              _inputRow("Kol", _armCtrl, "cm"),
              _inputRow("Üst Bacak", _legCtrl, "cm"),

              const Divider(height: 30),
              const Text("Ekstra / Özel (Örn: Omuz):",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 5),

              // ÖZEL GİRİŞ (Birim serbest)
              Row(
                children: [
                  Expanded(
                      flex: 3, child: _simpleInput("İsim", _customNameCtrl)),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2,
                      child: _simpleInput("Değer", _customValueCtrl,
                          isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      flex: 2, child: _simpleInput("Birim", _customUnitCtrl)),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Map<String, double> values = {};
              Map<String, String> units = {};

              // --- KAYIT MANTIĞI ---
              void addIfFilled(TextEditingController valCtrl, String fixedUnit,
                  String defaultName) {
                if (valCtrl.text.isNotEmpty) {
                  String valText = valCtrl.text.replaceAll(',', '.').trim();
                  double? val = double.tryParse(valText);
                  if (val != null) {
                    values[defaultName] = val;
                    units[defaultName] = fixedUnit;
                  }
                }
              }

              // Standartları ekle (Birimler kodda sabit)
              addIfFilled(_weightCtrl, "kg", "Kilo");
              addIfFilled(_fatCtrl, "%", "Yağ");
              addIfFilled(_waistCtrl, "cm", "Bel");
              addIfFilled(_chestCtrl, "cm", "Göğüs");
              addIfFilled(_armCtrl, "cm", "Kol");
              addIfFilled(_legCtrl, "cm", "Üst Bacak");

              // Özeli ekle
              if (_customNameCtrl.text.isNotEmpty &&
                  _customValueCtrl.text.isNotEmpty) {
                String valText =
                    _customValueCtrl.text.replaceAll(',', '.').trim();
                double? val = double.tryParse(valText);
                if (val != null) {
                  String name = _customNameCtrl.text.trim();
                  values[name] = val;
                  units[name] = _customUnitCtrl.text.trim();
                }
              }

              if (values.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("En az bir değer girmelisiniz!")));
                return;
              }

              final newM = MeasurementModel(
                  id: '',
                  memberId: widget.memberId,
                  date: DateTime.now(),
                  values: values,
                  units: units);

              _db.addMeasurement(newM);

              if (values.containsKey("Kilo")) {
                setState(() {
                  _selectedMetric = "Kilo";
                });
              } else {
                setState(() {
                  _selectedMetric = values.keys.first;
                });
              }

              Navigator.pop(ctx);
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _inputRow(
      String label, TextEditingController valCtrl, String fixedUnit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: valCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "0",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(fixedUnit,
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _simpleInput(String hint, TextEditingController ctrl,
      {bool isNumber = false}) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          labelText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // BİRİM BELİRLEME FONKSİYONU (Grafik için)
  String _getUnitForMetric(String metric, List<MeasurementModel> allData) {
    // 1. Standartlar için zorunlu birim (Grafik hatasını önler)
    if (metric == "Kilo") return "kg";
    if (metric == "Yağ" || metric == "Yağ Oranı") return "%";
    if (["Bel", "Göğüs", "Kol", "Bacak", "Üst Bacak"].contains(metric))
      return "cm";

    // 2. Özel ise veritabanından bul
    for (var m in allData.reversed) {
      if (m.units.containsKey(metric)) {
        return m.units[metric]!;
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MeasurementModel>>(
        stream: _db.getMeasurements(widget.memberId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                appBar: AppBar(),
                body: const Center(child: CircularProgressIndicator()));
          }

          final allData = snapshot.data ?? [];

          Set<String> availableMetrics = {"Kilo"};
          for (var m in allData) {
            availableMetrics.addAll(m.values.keys);
          }

          if (!availableMetrics.contains(_selectedMetric) &&
              availableMetrics.isNotEmpty) {
            _selectedMetric = availableMetrics.first;
          }

          List<MapEntry<DateTime, double>> chartPoints = [];

          _currentUnit = _getUnitForMetric(_selectedMetric, allData);

          for (var m in allData) {
            if (m.values.containsKey(_selectedMetric)) {
              chartPoints.add(MapEntry(m.date, m.values[_selectedMetric]!));
            }
          }

          // DÜZELTME: Type hatasını önlemek için .toList() kullanıldı
          final List<MeasurementModel> listData = allData.reversed.toList();

          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              centerTitle: true,
              title: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMetric,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  onChanged: (String? newValue) {
                    if (newValue != null)
                      setState(() => _selectedMetric = newValue);
                  },
                  items: availableMetrics
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("$value Grafiği"),
                    );
                  }).toList(),
                ),
              ),
            ),
            body: allData.isEmpty
                ? _buildEmptyState(listData)
                : Column(
                    children: [
                      Container(
                        height: 300,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.fromLTRB(16, 24, 24, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 15,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("$_selectedMetric Gelişimi ($_currentUnit)",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 20),
                            Expanded(child: _buildChart(chartPoints)),
                          ],
                        ),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Ölçüm Geçmişi",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18))),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: listData.length,
                          itemBuilder: (context, index) {
                            return _buildDetailCard(listData[index]);
                          },
                        ),
                      ),
                    ],
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddDialog(listData),
              backgroundColor: Colors.black,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Ölçüm Ekle",
                  style: TextStyle(color: Colors.white)),
            ),
          );
        });
  }

  Widget _buildDetailCard(MeasurementModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: const Icon(LineIcons.calendar,
                        size: 18, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(m.date),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(LineIcons.trash,
                    size: 20, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirm(m.id),
              )
            ],
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: m.values.entries.map((entry) {
              String key = entry.key;
              double val = entry.value;

              // Kartta gösterirken veritabanındaki birimi kullan (Özel olanlar için)
              // Ancak standartlar için yine zorla düzeltebiliriz ama veritabanındaki de doğrudur
              String unit = m.units[key] ?? "";

              bool isSelected = (key == _selectedMetric);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300),
                ),
                child: Text("$key: $val $unit",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87)),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildChart(List<MapEntry<DateTime, double>> data) {
    if (data.length < 2)
      return const Center(
          child: Text("Grafik için bu türde en az 2 veri gerekli.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)));

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].value));
    }

    double minY = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY - (minY * 0.05),
        maxY: maxY + (maxY * 0.05),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final date = DateFormat('dd/MM').format(data[index].key);
                return LineTooltipItem(
                    "$date\n${spot.y} $_currentUnit",
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold));
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40, interval: null)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < data.length) {
                  if (data.length > 6 && index % 2 != 0)
                    return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                        DateFormat('d MMM', 'tr_TR').format(data[index].key),
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.0)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu ölçüm kaydı kalıcı olarak silinecek."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
              onPressed: () {
                _db.deleteMeasurement(id);
                Navigator.pop(ctx);
              },
              child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<MeasurementModel> history) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LineIcons.ruler, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Henüz bir ölçüm girilmedi.",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () => _showAddDialog(history),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("İlk Ölçümü Ekle",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
