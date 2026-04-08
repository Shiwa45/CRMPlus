void main() {
  dynamic x = 5;
  try {
    print(x['name']);
  } catch (e) {
    print(e.toString());
  }
}
