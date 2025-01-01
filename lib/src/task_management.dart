library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task_provider.dart';
import 'model/tag_model.dart';

class TaskManagement extends StatefulWidget {
  final double width;
  final Color backgroundColor;
  final Widget Function(TagModel) headingBuilder;
  final double itemWidth;
  final Widget Function(Map<String, dynamic> task, int index, TagModel heading)
      taskBuilder;
  final List<TagModel> headings;
  final List<Map<String, dynamic>> itemData;
  final GlobalKey containerKey;
  final double highlightedPipeWidth;

  const TaskManagement({
    super.key,
    required this.width,
    required this.backgroundColor,
    required this.headingBuilder,
    required this.itemWidth,
    required this.taskBuilder,
    required this.headings,
    required this.itemData,
    required this.containerKey,
    required this.highlightedPipeWidth,
  });

  @override
  State<TaskManagement> createState() => _TaskManagementState();
}

class _TaskManagementState extends State<TaskManagement> {
  @override
  void initState() {
    // TODO: implement initState

    validateDataAndTags(widget.headings, widget.itemData);
    if (validateDataAndTags(widget.headings, widget.itemData)) {
      TaskProvider taskProvider = Provider.of(context, listen: false);
      taskProvider.setData(widget.headings, widget.itemData);
    }

    super.initState();
  }

  List<Map<String, dynamic>> invalidTasks = [];
  Set<String> missingStatuses = {};
  Set<String> duplicateHeadings = {};

  bool validateDataAndTags(
      List<TagModel> tags, List<Map<String, dynamic>> data) {
    // Clear previous validation results
    invalidTasks.clear();
    missingStatuses.clear();
    duplicateHeadings.clear();

    // Extract all valid statuses from the tags
    final validStatuses = tags.map((tag) => tag.status).toSet();

    // Detect duplicate headings
    final seenHeadings = <String>{};
    for (var tag in tags) {
      if (seenHeadings.contains(tag.heading)) {
        duplicateHeadings.add(tag.heading);
      } else {
        seenHeadings.add(tag.heading);
      }
    }

    // Check each task in the data
    for (var task in data) {
      if (!validStatuses.contains(task['status'])) {
        invalidTasks.add(task);
        missingStatuses.add(task['status']);
      }
    }

    // Provide feedback
    if (duplicateHeadings.isNotEmpty) {
      print("Validation failed: Duplicate headings found in tags.");
      for (var heading in duplicateHeadings) {
        print("Duplicate Heading: $heading");
      }
    }

    if (invalidTasks.isEmpty && duplicateHeadings.isEmpty) {
      print(
          "Validation successful: All tasks have valid statuses and no duplicate headings.");
      return true;
    } else {
      if (invalidTasks.isNotEmpty) {
        print("Validation failed: Some tasks have invalid statuses.");
        print("Invalid Tasks:");
        for (var task in invalidTasks) {
          print(
              "Task ID: ${task['id']}, Status: ${task['status']} not defined in heading data.");
        }

        print("Statuses in data but not found in tags:");
        for (var status in missingStatuses) {
          print(status);
        }
      }

      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return (!validateDataAndTags(widget.headings, widget.itemData))
        ? Column(
            children: [
              Text(
                "Validation failed. Please make sure all tasks have valid status.",
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 16),
              Container(
                color: Colors.grey,
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Invalid Tasks:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...invalidTasks.map((task) {
                return ListTile(
                  title: Text(
                    "Task ID: ${task['id']}, Status: ${task['status']} (not define in heading data)",
                  ),
                );
              }),
              SizedBox(height: 16),
              Container(
                color: Colors.grey,
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Statuses in data but not found in tags:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...duplicateHeadings.map((heading) {
                return ListTile(
                  title: Text(
                    "Duplicate Headings : $heading",
                  ),
                );
              }),
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              key: widget.containerKey,
              children: widget.headings.map((heading) {
                return Container(
                  width: widget.width,
                  color: widget.backgroundColor,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      widget.headingBuilder(heading),
                      Expanded(
                        child: DragTarget<Map<String, dynamic>>(
                          onWillAcceptWithDetails: (taskDetails) {
                            context
                                .read<TaskProvider>()
                                .setCurrentDraggingSection(heading.status);

                            final renderBox = widget
                                .containerKey.currentContext!
                                .findRenderObject() as RenderBox;

                            context
                                .read<TaskProvider>()
                                .findDropIndex(taskDetails.offset, renderBox);

                            return true;
                          },
                          onAcceptWithDetails: (taskDetails) {
                            context.read<TaskProvider>().updateTaskPosition(
                                  taskDetails.data,
                                  heading.status,
                                  context
                                          .read<TaskProvider>()
                                          .highlightedIndex ??
                                      context
                                          .read<TaskProvider>()
                                          .groupedData[heading.status]!
                                          .length,
                                );
                            context.read<TaskProvider>().resetDragState();
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Consumer<TaskProvider>(
                              builder: (context, taskProvider, child) {
                                return NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    return true;
                                  },
                                  child: ListView.builder(
                                    controller: taskProvider
                                        .scrollControllers[heading.status],
                                    shrinkWrap: true,
                                    itemCount: taskProvider
                                            .groupedData[heading.status]
                                            ?.length ??
                                        0,
                                    itemBuilder: (context, index) {
                                      final task = taskProvider
                                          .groupedData[heading.status]![index];
                                      return Column(
                                        children: [
                                          if (taskProvider
                                                      .currentDraggingSection ==
                                                  heading.status &&
                                              taskProvider.highlightedIndex ==
                                                  index) ...[
                                            Container(
                                              height: 4,
                                              width:
                                                  widget.highlightedPipeWidth,
                                              color: Colors.blue,
                                            ),
                                          ],
                                          LongPressDraggable<
                                              Map<String, dynamic>>(
                                            data: task,
                                            onDragUpdate: (details) {
                                              final renderBox =
                                                  widget.containerKey
                                                          .currentContext!
                                                          .findRenderObject()
                                                      as RenderBox;
                                              taskProvider.findDropIndex(
                                                  details.globalPosition,
                                                  renderBox);

                                              final scrollController = taskProvider
                                                      .scrollControllers[
                                                  taskProvider
                                                      .currentDraggingSection]!;
                                              const double scrollThreshold =
                                                  50.0;

                                              if (details.localPosition.dy <
                                                  scrollThreshold) {
                                                scrollController.animateTo(
                                                  scrollController.offset - 50,
                                                  duration: const Duration(
                                                      milliseconds: 50),
                                                  curve: Curves.linear,
                                                );
                                              } else if (details
                                                      .localPosition.dy >
                                                  renderBox.size.height -
                                                      scrollThreshold) {
                                                scrollController.animateTo(
                                                  scrollController.offset + 50,
                                                  duration: const Duration(
                                                      milliseconds: 50),
                                                  curve: Curves.linear,
                                                );
                                              }
                                            },
                                            feedback: SizedBox(
                                              height: 200,
                                              width: widget.itemWidth,
                                              child: widget.taskBuilder(
                                                  task, index, heading),
                                            ),
                                            child: SizedBox(
                                              height: 200,
                                              width: widget.itemWidth,
                                              child: widget.taskBuilder(
                                                  task, index, heading),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
  }
}
