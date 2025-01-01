library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'model/tag_model.dart';

class TaskProvider extends ChangeNotifier {
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  Map<String, ScrollController> scrollControllers = {};

  int? highlightedIndex;
  String? currentDraggingSection;

  void setData(List<TagModel> headings, List<Map<String, dynamic>> data) {
    // Clear any existing data to avoid duplications
    groupedData.clear();
    scrollControllers.clear();

    // Initialize groupedData and scrollControllers for each heading
    for (var heading in headings) {
      groupedData[heading.status] = [];
      scrollControllers[heading.status] = ScrollController();
    }

    // Populate groupedData based on the status in the data
    for (var item in data) {
      if (groupedData.containsKey(item['status'])) {
        groupedData[item['status']]?.add(item);
      }
    }
    print(groupedData);
  }

  void setCurrentDraggingSection(String section) {
    currentDraggingSection = section;
    notifyListeners();
  }

  void updateTaskPosition(
      Map<String, dynamic> task, String newStatus, int newIndex) {
    for (var section in groupedData.values) {
      section.remove(task);
    }
    task['status'] = newStatus;
    if (newIndex < 0 || newIndex > groupedData[newStatus]!.length) {
      newIndex = groupedData[newStatus]!.length;
    }
    groupedData[newStatus]?.insert(newIndex, task);
    notifyListeners();
  }

  void findDropIndex(Offset globalOffset, RenderBox renderBox) {
    if (currentDraggingSection == null) return;

    final scrollOffset = scrollControllers[currentDraggingSection]!.offset;
    final localOffset = renderBox.globalToLocal(globalOffset);

    final List<Map<String, dynamic>> sectionData =
    groupedData[currentDraggingSection]!;

    for (int index = 0; index < sectionData.length; index++) {
      final double itemHeight = 200; // Approximate height of each item
      final double startY = (index * itemHeight) - scrollOffset;
      final double endY = startY + itemHeight;

      if (localOffset.dy >= startY && localOffset.dy < endY) {
        highlightedIndex = index;
        notifyListeners();
        break;
      }
    }
  }

  void resetDragState() {
    highlightedIndex = null;
    currentDraggingSection = null;
    notifyListeners();
  }
}
