import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';

SourceRange methodOverrideDeletionRange(MethodDeclaration method, String content) {
  final startOffset = method.metadata.isNotEmpty ? method.metadata.first.offset : method.offset;

  var deleteStart = startOffset;
  while (deleteStart > 0 && content[deleteStart - 1] != '\n') {
    deleteStart--;
  }

  var deleteEnd = method.end;
  while (deleteEnd < content.length && content[deleteEnd] != '\n') {
    deleteEnd++;
  }
  if (deleteEnd < content.length && content[deleteEnd] == '\n') {
    deleteEnd++;
  }

  if (deleteStart > 0 && content[deleteStart - 1] == '\n') {
    deleteStart--;
  }

  return SourceRange(deleteStart, deleteEnd - deleteStart);
}
