import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../models/class_model.dart';
import '../../models/member_model.dart';
import '../../providers/auth_provider.dart';

class ClassManagerScreen extends StatefulWidget {
  const ClassManagerScreen({super.key});

  @override
  State<ClassManagerScreen> createState() => _ClassManagerScreenState();
}

class _ClassManagerScreenState extends State<ClassManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final db = DatabaseService(gymId: auth.gymId);

    return Scaffold(
      appBar: AppBar(title: const Text("Sınıf ve Grup Yönetimi")),
      body: StreamBuilder<List<ClassCategory>>(
        stream: db.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // KATEGORİ EKLEME BUTONU
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Yeni Kategori Ekle"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () => _showCategoryDialog(context, db, null),
              ),
              const SizedBox(height: 20),

              // KATEGORİ LİSTESİ
              ...categories
                  .map((category) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: ExpansionTile(
                          // Başlık ve İkonlar
                          title: Text(category.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // KATEGORİ DÜZENLEME
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showCategoryDialog(context, db, category),
                              ),
                              // KATEGORİ SİLME
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context,
                                    () => db.deleteCategory(category.id)),
                              ),
                            ],
                          ),
                          children: [
                            // KATEGORİNİN İÇİNDEKİ GRUPLAR
                            _GroupsList(
                                categoryId: category.id,
                                categoryName: category.name,
                                db: db),
                          ],
                        ),
                      ))
                  .toList()
            ],
          );
        },
      ),
    );
  }

  // SİLME ONAY KUTUSU (Yanlışlıkla silmeleri önlemek için)
  void _confirmDelete(BuildContext context, Function onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Emin misiniz?"),
        content: const Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
              onPressed: () {
                onDelete();
                Navigator.pop(ctx);
              },
              child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // KATEGORİ EKLEME VE DÜZENLEME DİYALOĞU
  // Eğer 'category' parametresi dolu gelirse "Düzenle", boş gelirse "Ekle" modunda çalışır.
  void _showCategoryDialog(
      BuildContext context, DatabaseService db, ClassCategory? category) {
    final isEditing = category != null;
    final ctrl = TextEditingController(text: isEditing ? category.name : "");

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text(isEditing ? "Kategoriyi Düzenle" : "Yeni Kategori"),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(hintText: "Kategori Adı")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        if (isEditing) {
                          db.updateCategory(category.id, ctrl.text);
                        } else {
                          db.addCategory(ctrl.text);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(isEditing ? "Güncelle" : "Ekle")),
              ],
            ));
  }
}

class _GroupsList extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final DatabaseService db;

  const _GroupsList({
    required this.categoryId,
    required this.categoryName,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClassGroup>>(
      stream: db.getGroups(categoryId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final groups = snapshot.data!;

        return Column(
          children: [
            if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Henüz grup eklenmemiş.",
                    style: TextStyle(color: Colors.grey)),
              ),
            ...groups.map((group) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  title: Text(group.name),
                  subtitle: Text("${group.memberIds.length} Öğrenci"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GRUP DÜZENLEME
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 20, color: Colors.blue),
                        onPressed: () => _showGroupDialog(
                            context, db, categoryId, categoryName, group),
                      ),
                      // GRUP SİLME
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () => db.deleteGroup(group.id),
                      ),
                    ],
                  ),
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Bu Kategoriye Grup Ekle"),
                onPressed: () => _showGroupDialog(
                    context, db, categoryId, categoryName, null),
              ),
            )
          ],
        );
      },
    );
  }

  // GRUP EKLEME VE DÜZENLEME (Bottom Sheet)
  // group parametresi null ise "Ekle", dolu ise "Düzenle"
  void _showGroupDialog(BuildContext context, DatabaseService db, String catId,
      String catName, ClassGroup? group) {
    final isEditing = group != null;
    final nameCtrl = TextEditingController(text: isEditing ? group.name : "");

    // Eğer düzenliyorsak mevcut üyeleri listeye al, yoksa boş liste
    List<String> selectedMembers = isEditing ? List.from(group.memberIds) : [];

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(builder: (c, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEditing ? "Grubu Düzenle" : "Yeni Grup Oluştur",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close))
                    ],
                  ),
                  Text("Kategori: $catName",
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          hintText: "Grup Adı (Örn: Gençler)",
                          prefixIcon: Icon(Icons.group))),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Öğrencileri Seç:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("${selectedMembers.length} Seçili",
                          style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<List<MemberModel>>(
                      stream: db.getMembers(), // Tüm üyeleri getir
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // İsteğe bağlı: İsme göre sıralama yapabiliriz
                        var members = snap.data!;

                        return ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final m = members[index];
                            final isSelected = selectedMembers.contains(m.id);

                            return CheckboxListTile(
                              dense: true,
                              activeColor: Colors.black,
                              title: Text(m.name),
                              subtitle: Text(
                                  m.phone), // Hangi Veli olduğunu anlamak için
                              value: isSelected,
                              onChanged: (val) {
                                setStateModal(() {
                                  if (val == true) {
                                    selectedMembers.add(m.id);
                                  } else {
                                    selectedMembers.remove(m.id);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty) {
                          if (isEditing) {
                            // GÜNCELLEME
                            db.updateGroup(
                                group.id, nameCtrl.text, selectedMembers);
                          } else {
                            // YENİ EKLEME
                            db.addGroup(
                                catId, catName, nameCtrl.text, selectedMembers);
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(isEditing
                          ? "Değişiklikleri Kaydet"
                          : "Grubu Oluştur"),
                    ),
                  )
                ],
              ),
            );
          });
        });
  }
}
