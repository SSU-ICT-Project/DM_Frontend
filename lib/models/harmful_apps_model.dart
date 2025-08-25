class HarmfulAppsModel {
  final List<String> distractionAppList;

  HarmfulAppsModel({
    required this.distractionAppList,
  });

  Map<String, dynamic> toJson() {
    return {
      'distractionAppList': distractionAppList,
    };
  }

  factory HarmfulAppsModel.fromJson(Map<String, dynamic> json) {
    return HarmfulAppsModel(
      distractionAppList: List<String>.from(json['distractionAppList'] ?? []),
    );
  }

  @override
  String toString() {
    return 'HarmfulAppsModel(distractionAppList: $distractionAppList)';
  }
}
