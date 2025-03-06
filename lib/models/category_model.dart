class Category {
  String catName;

  Category({required this.catName});

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      catName: data['catName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'catName': catName,
    };
  }
}
