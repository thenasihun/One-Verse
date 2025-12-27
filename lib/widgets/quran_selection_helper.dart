import 'package:flutter/material.dart';
import 'package:oneverse/models/surah_model.dart';

class QuranSelectionHelper {
  static void showSurahSheet({
    required BuildContext context,
    required List<Surah> surahs,
    required Function(Surah) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _SurahSearchList(
                  controller: controller, surahs: surahs, onSelect: onSelect),
            ],
          ),
        ),
      ),
    );
  }

  static void showAyahSheet({
    required BuildContext context,
    required int totalAyahs,
    required int selectedAyah,
    required Function(int) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            _buildHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text("Select Ayah",
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: totalAyahs,
                itemBuilder: (context, index) {
                  final num = index + 1;
                  bool isSelected = num == selectedAyah;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(num);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text("$num",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : null)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHandle() => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10)),
      );
}

class _SurahSearchList extends StatefulWidget {
  final ScrollController controller;
  final List<Surah> surahs;
  final Function(Surah) onSelect;
  const _SurahSearchList(
      {required this.controller, required this.surahs, required this.onSelect});

  @override
  State<_SurahSearchList> createState() => _SurahSearchListState();
}

class _SurahSearchListState extends State<_SurahSearchList> {
  late List<Surah> filtered;
  @override
  void initState() {
    super.initState();
    filtered = widget.surahs;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => filtered = widget.surahs
                  .where((s) =>
                      s.englishName.toLowerCase().contains(v.toLowerCase()) ||
                      s.number.toString() == v)
                  .toList()),
              decoration: InputDecoration(
                hintText: "Search Surah...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: widget.controller,
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final s = filtered[i];
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text("${s.number}",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                  title: Text(s.englishName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text("${s.revelationType} • ${s.numberOfAyahs} Ayahs"),
                  trailing: Text(s.name,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelect(s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
