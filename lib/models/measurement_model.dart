import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementModel {
  final String id;
  final String memberId;
  final DateTime date;
  // Esnek Veri Yapısı: {"Kilo": 80.5, "Bel": 90.0, "Sağ Kol": 35.0}
  final Map<String, double> values;
  // Birim Yapısı: {"Kilo": "kg", "Bel": "cm", "Sağ Kol": "cm"}
  final Map<String, String> units;

  MeasurementModel({
    required this.id,
    required this.memberId,
    required this.date,
    required this.values,
    required this.units,
  });

  factory MeasurementModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // Güvenli Map Çevirici
    Map<String, double> parsedValues = {};
    Map<String, String> parsedUnits = {};

    if (data['values'] != null) {
      (data['values'] as Map<String, dynamic>).forEach((key, value) {
        parsedValues[key] = (value as num).toDouble();
      });
    }

    if (data['units'] != null) {
      (data['units'] as Map<String, dynamic>).forEach((key, value) {
        parsedUnits[key] = value.toString();
      });
    }

    // Eski veri yapısı varsa (Kilo vs.) patlamaması için manuel kontrol (Opsiyonel Migration)
    if (parsedValues.isEmpty && data.containsKey('weight')) {
      parsedValues['Kilo'] = (data['weight'] as num).toDouble();
      parsedUnits['Kilo'] = 'kg';
    }

    return MeasurementModel(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      date: data['date'] != null
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      values: parsedValues,
      units: parsedUnits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'date': Timestamp.fromDate(date),
      'values': values,
      'units': units,
    };
  }
}
