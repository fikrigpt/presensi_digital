import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frontend/models/user.dart';
import 'package:frontend/models/attendance.dart';
import 'package:frontend/models/employee.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  static const String baseUrl = 'http://localhost:5000/api';

  Future<dynamic> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    return json.decode(response.body);
  }

  Future<List<Attendance>> getAttendanceHistory(int userId,
      {DateTime? startDate, DateTime? endDate}) async {
    String url = '$baseUrl/attendance/history/$userId';

    if (startDate != null && endDate != null) {
      url +=
          '?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendance history');
    }
  }

  Future<List<Attendance>> getAttendanceReport(
      {int? employeeId, String? startDate, String? endDate}) async {
    String url = '$baseUrl/attendance/report?';
    if (employeeId != null) {
      url += 'employee_id=$employeeId&';
    }
    if (startDate != null) {
      url += 'start_date=$startDate&';
    }
    if (endDate != null) {
      url += 'end_date=$endDate';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Attendance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load attendance report');
    }
  }

  Future<List<Employee>> getEmployees() async {
    final response = await http.get(Uri.parse('$baseUrl/employees'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Employee.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load employees');
    }
  }

  Future<Map<String, dynamic>> createEmployee(
      Map<String, dynamic> data, File? imageFile, Uint8List? imageBytes) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/employees'));

    // Add text fields
    request.fields['username'] = data['username'];
    request.fields['password'] = data['password'];
    request.fields['nama'] = data['nama'];
    request.fields['umur'] = data['umur'].toString();
    request.fields['domisili'] = data['domisili'];
    request.fields['jabatan'] = data['jabatan'];

    // ANDROID → pakai File
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );
    }

    // WEB → pakai Bytes
    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          imageBytes,
          filename: "upload.png",
          contentType: MediaType("image", "png"),
        ),
      );
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    return json.decode(responseData);
  }

  Future<Map<String, dynamic>> updateEmployee(int id, Map<String, dynamic> data,
      File? imageFile, Uint8List? imageBytes) async {
    var request =
        http.MultipartRequest('PUT', Uri.parse('$baseUrl/employees/$id'));

    request.fields['nama'] = data['nama'];
    request.fields['umur'] = data['umur'].toString();
    request.fields['domisili'] = data['domisili'];
    request.fields['jabatan'] = data['jabatan'];

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', imageFile.path),
      );
    }

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'foto',
          imageBytes,
          filename: "upload.png",
          contentType: MediaType("image", "png"),
        ),
      );
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    return json.decode(responseData);
  }

  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/employees/$id'));
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> checkIn(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-in'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId}),
    );

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> checkOut(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/check-out'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_id': userId}),
    );

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> requestLeave(
      int userId, String status, String keterangan,
      {DateTime? tanggal}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/leave'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'status': status,
        'keterangan': keterangan,
        'tanggal': tanggal?.toIso8601String().split('T')[0],
      }),
    );

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> changePassword(
      int userId, String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    return json.decode(response.body);
  }

  Future<User> getUser(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId'));

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
      int userId, String username, String nama,
      {String? jabatan}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'nama': nama,
      }),
    );

    return json.decode(response.body);
  }
}
