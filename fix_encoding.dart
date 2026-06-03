import 'dart:io';

void main() {
  final dir = Directory('d:/FLUTTER PROJECTS/TRIPEASE/tripease/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int count = 0;
  for (var file in files) {
    try {
      String content = file.readAsStringSync();
      if (content.contains('â‚¹') || content.contains('â€¢') || content.contains('â†’') || content.contains('â”€') || content.contains('â€”')) {
        content = content.replaceAll('â‚¹', '₹');
        content = content.replaceAll('â€¢', '•');
        content = content.replaceAll('â†’', '→');
        content = content.replaceAll('â”€', '─');
        content = content.replaceAll('â€”', '—');
        file.writeAsStringSync(content);
        count++;
        print('Fixed ${file.path}');
      }
    } catch (e) {
      print('Error reading ${file.path}: $e');
    }
  }
  print('Total files fixed: $count');
}
