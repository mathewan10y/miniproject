class VarsityLevel {
  final String id;
  final String name; // e.g. "The Recruit"
  final String title; // e.g. "Level 1"
  final String description;
  final List<String> modules;
  final bool isLocked;

  const VarsityLevel({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.modules,
    this.isLocked = false,
  });
}
