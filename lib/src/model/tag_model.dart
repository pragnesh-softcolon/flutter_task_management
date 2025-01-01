library;

class TagModel {
  String heading;
  int color;
  String status;

  TagModel({required this.heading, required this.color, required this.status});

  // Convert a TagModel instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'heading': heading,
      'color': color,
      'status': status,
    };
  }

  // Create a TagModel instance from JSON
  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      heading: json['heading'],
      color: json['color'],
      status: json['status'],
    );
  }

  // Convert a list of TagModel instances to JSON
  static List<Map<String, dynamic>> listToJson(List<TagModel> tags) {
    return tags.map((tag) => tag.toJson()).toList();
  }

  // Create a list of TagModel instances from JSON
  static List<TagModel> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => TagModel.fromJson(json)).toList();
  }
}
