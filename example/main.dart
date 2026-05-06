void main() {
  final message = buildGreeting('Flutter');
  assert(message == 'Hello, Flutter');
}

String buildGreeting(String name) => 'Hello, $name';
