import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/models/employee.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/services/api_service.dart';

class EmployeeCRUDDialog extends StatefulWidget {
  final VoidCallback onEmployeeUpdated;

  EmployeeCRUDDialog({required this.onEmployeeUpdated});

  @override
  _EmployeeCRUDDialogState createState() => _EmployeeCRUDDialogState();
}

// deteksi apakah apk dijalankan di emu/web
String getBaseUrl() {
  if (kIsWeb) {
    return "http://localhost:5000";
  }
  if (Platform.isAndroid) {
    return "http://10.0.2.2:5000";
  }
  return "http://localhost:5000";
}

class _EmployeeCRUDDialogState extends State<EmployeeCRUDDialog> {
  final ApiService _api = ApiService();
  List<Employee> _employees = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Uint8List? localSelectedImageBytes;
  File? localSelectedImage;
  // list jabatan
  final List<String> _jabatanList = [
    'Manager',
    'Supervisor',
    'Staff Admin',
    'Staff IT',
    'Programmer',
    'Staff Marketing',
    'Staff Operasional',
    'Staff Gudang',
    'Sales'
  ];
  String? _selectedJabatan;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() async {
    try {
      final employees = await _api.getEmployees();
      setState(() {
        _employees = employees.where((e) => e.username != 'hrd').toList();
      });
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  void _addEmployee() {
    final formKey = GlobalKey<FormState>();
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    TextEditingController namaController = TextEditingController();
    TextEditingController umurController = TextEditingController();
    TextEditingController domisiliController = TextEditingController();
    _selectedJabatan = null;
    localSelectedImage = null;
    localSelectedImageBytes = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF667EEA).withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.person_add,
                          size: 32,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tambah Karyawan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 24),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final pickedFile = await _picker.pickImage(
                                    source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  if (kIsWeb) {
                                    final bytes =
                                        await pickedFile.readAsBytes();
                                    setDialogState(() {
                                      localSelectedImageBytes = bytes;
                                      localSelectedImage = null;
                                    });
                                  } else {
                                    setDialogState(() {
                                      localSelectedImage =
                                          File(pickedFile.path);
                                      localSelectedImageBytes = null;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (localSelectedImageBytes != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.memory(
                                          localSelectedImageBytes!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else if (localSelectedImage != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.file(
                                          localSelectedImage!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            size: 32,
                                            color: Colors.grey[500],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Tambahkan Foto',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF667EEA),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            TextFormField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username harus diisi';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password harus diisi';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: namaController,
                              decoration: InputDecoration(
                                labelText: 'Nama Lengkap',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama harus diisi';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: umurController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Umur',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.cake_outlined,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: domisiliController,
                              decoration: InputDecoration(
                                labelText: 'Domisili',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedJabatan,
                              decoration: InputDecoration(
                                labelText: 'Jabatan',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.work_outline,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _jabatanList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  _selectedJabatan = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Pilih jabatan';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context);

                                  if (!mounted) return;
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    final data = {
                                      'username': usernameController.text,
                                      'password': passwordController.text,
                                      'nama': namaController.text,
                                      'umur': int.tryParse(umurController.text),
                                      'domisili': domisiliController.text,
                                      'jabatan': _selectedJabatan,
                                    };

                                    _selectedJabatan = null;

                                    final response = await _api.createEmployee(
                                      data,
                                      localSelectedImage,
                                      localSelectedImageBytes,
                                    );

                                    if (response['success'] == true) {
                                      _showSuccessDialog(
                                          'Karyawan berhasil ditambahkan');
                                      _loadEmployees();
                                      widget.onEmployeeUpdated();
                                    } else {
                                      _showErrorDialog(response['error'] ??
                                          'Gagal menambahkan karyawan');
                                    }
                                  } catch (e) {
                                    _showErrorDialog('Error: $e');
                                  } finally {
                                    if (!mounted) return;
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editEmployee(Employee employee) {
    final formKey = GlobalKey<FormState>();
    TextEditingController namaController =
        TextEditingController(text: employee.nama);
    TextEditingController umurController =
        TextEditingController(text: employee.umur?.toString() ?? '');
    TextEditingController domisiliController =
        TextEditingController(text: employee.domisili ?? '');
    _selectedJabatan = employee.jabatan;
    File? localSelectedImage;
    localSelectedImage = null;
    localSelectedImageBytes = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF667EEA).withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 32,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Edit Karyawan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 24),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final pickedFile = await _picker.pickImage(
                                    source: ImageSource.gallery);

                                if (pickedFile != null) {
                                  if (kIsWeb) {
                                    final bytes =
                                        await pickedFile.readAsBytes();
                                    setDialogState(() {
                                      localSelectedImageBytes = bytes;
                                      localSelectedImage = null;
                                    });
                                  } else {
                                    setDialogState(() {
                                      localSelectedImage =
                                          File(pickedFile.path);
                                      localSelectedImageBytes = null;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (localSelectedImageBytes != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.memory(
                                          localSelectedImageBytes!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else if (localSelectedImage != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.file(
                                          localSelectedImage!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else if (employee.foto != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(48),
                                        child: Image.network(
                                          employee.foto!.startsWith('http')
                                              ? employee.foto!
                                              : '${getBaseUrl()}/uploads/${employee.foto}',
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 32,
                                            color: Colors.grey[500],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Ganti Foto',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF667EEA),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            TextFormField(
                              controller: namaController,
                              decoration: InputDecoration(
                                labelText: 'Nama Lengkap',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nama harus diisi';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: umurController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Umur',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.cake_outlined,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: domisiliController,
                              decoration: InputDecoration(
                                labelText: 'Domisili',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedJabatan ?? employee.jabatan,
                              decoration: InputDecoration(
                                labelText: 'Jabatan',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                prefixIcon: Icon(
                                  Icons.work_outline,
                                  color: Color(0xFF667EEA),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Color(0xFF667EEA),
                                    width: 2,
                                  ),
                                ),
                              ),
                              items: _jabatanList.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  _selectedJabatan = newValue;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context);

                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    final data = {
                                      'nama': namaController.text,
                                      'umur': int.tryParse(umurController.text),
                                      'domisili': domisiliController.text,
                                      'jabatan':
                                          _selectedJabatan ?? employee.jabatan,
                                    };
                                    _selectedJabatan = null;

                                    final response = await _api.updateEmployee(
                                      employee.id,
                                      data,
                                      localSelectedImage,
                                      localSelectedImageBytes,
                                    );

                                    if (response['success'] == true) {
                                      _showSuccessDialog(
                                          'Data karyawan berhasil diperbarui');
                                      _loadEmployees();
                                      widget.onEmployeeUpdated();
                                    } else {
                                      _showErrorDialog(
                                          'Gagal memperbarui data karyawan');
                                    }
                                  } catch (e) {
                                    _showErrorDialog('Error: $e');
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF667EEA),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteEmployee(int employeeId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  size: 32,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Hapus Karyawan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin menghapus karyawan ini?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Tindakan ini tidak dapat dibatalkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        if (!mounted) return;
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          final response =
                              await _api.deleteEmployee(employeeId);

                          if (!mounted) return;
                          if (response['success'] == true) {
                            _showSuccessDialog('Karyawan berhasil dihapus');
                            _loadEmployees();
                            widget.onEmployeeUpdated();
                          } else {
                            _showErrorDialog(response['error'] ??
                                'Gagal menghapus karyawan');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showErrorDialog('Error: $e');
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF667EEA).withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 22,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Kelola Karyawan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _addEmployee,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
                label: Text(
                  'Tambah Karyawan Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF667EEA),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Memuat data karyawan...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _employees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada data karyawan',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Mulai dengan menambahkan karyawan baru',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _employees.length,
                          itemBuilder: (context, index) {
                            final employee = _employees[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Material(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: employee.foto != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            child: Image.network(
                                              employee.foto!.startsWith('http')
                                                  ? employee.foto!
                                                  : '${getBaseUrl()}/uploads/${employee.foto}',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Color(0xFF667EEA)
                                                .withOpacity(0.1),
                                            child: Icon(
                                              Icons.person,
                                              color: Color(0xFF667EEA),
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    employee.nama,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      if (employee.jabatan != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.work_outline,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              employee.jabatan!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (employee.domisili != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              employee.domisili!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (employee.umur != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.cake_outlined,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              '${employee.umur} tahun',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue.withOpacity(0.1),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _editEmployee(employee),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.withOpacity(0.1),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteEmployee(employee.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
