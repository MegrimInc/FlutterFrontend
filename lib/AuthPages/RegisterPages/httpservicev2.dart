
import 'package:http/http.dart' as http;

class HttpService {

Future<void> hello() async {
print("start parse");
  final temp = Uri.parse('http://10.155.32.54:8080/hello');
  String temp2 = temp.toString();
print("finish parse, start http.get $temp2");
  final response = await http.get(temp);
print("finished http get");

  if (response.statusCode == 200) {
print('Response data: ${response.body}');
  } else {
print('Request failed with status: ${response.statusCode}.');
  }
}
}