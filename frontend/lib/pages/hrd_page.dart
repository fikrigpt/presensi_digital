import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/employee.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/attendance_history.dart';
import 'package:frontend/widgets/employee_crud.dart';
import 'package:frontend/widgets/profile_dialog.dart';
import 'dart:async';
import '../models/attendance.dart';

class HRDPage extends StatefulWidget {
  final Map<String, dynamic> user;

  HRDPage({required this.user});

  @override
  _HRDPageState createState() => _HRDPageState();
}

class _HRDPageState extends State<HRDPage> {
  late DateTime _currentTime;
  late Timer _timer;
  final ApiService _api = ApiService();
  bool _isLoading = false;
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  List<Employee> _employees = [];
  List<Attendance> _attendanceReport = [];
  int? _selectedEmployeeFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _checkTodayAttendance();
    _loadEmployees();
    _loadAttendanceReport();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkTodayAttendance() async {
    try {
      final history = await _api.getAttendanceHistory(widget.user['id']);
      final today = DateTime.now();

      for (var record in history) {
        if (record.tanggal.year == today.year &&
            record.tanggal.month == today.month &&
            record.tanggal.day == today.day) {
          setState(() {
            _hasCheckedIn = record.checkIn != null;
            _hasCheckedOut = record.checkOut != null;
          });
          break;
        }
      }
    } catch (e) {
      print('Error checking attendance: $e');
    }
  }

  void _loadEmployees() async {
    try {
      final employees = await _api.getEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      print('Error loading employees: $e');
    }
  }

  void _loadAttendanceReport() async {
    try {
      final report = await _api.getAttendanceReport(
        employeeId: _selectedEmployeeFilter,
        startDate: _formatDate(_startDateFilter),
        endDate: _formatDate(_endDateFilter),
      );

      if (!mounted) return;
      setState(() {
        _attendanceReport = report;
      });
    } catch (e) {
      print('Error loading attendance report: $e');
    }
  }

  void _checkIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _api.checkIn(widget.user['id']);

      if (response['success'] == true) {
        setState(() {
          _hasCheckedIn = true;
        });
        _showSuccessDialog('Check-in berhasil!');
      } else {
        _showErrorDialog(response['message']);
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _api.checkOut(widget.user['id']);

      if (response['success'] == true) {
        setState(() {
          _hasCheckedOut = true;
        });
        _showSuccessDialog('Check-out berhasil!');
      } else {
        _showErrorDialog(response['message']);
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _requestLeave() {
    showDialog(
      context: context,
      builder: (context) {
        String leaveType = 'izin';
        TextEditingController reasonController = TextEditingController();
        DateTime selectedDate = DateTime.now();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Center(
                child: Text(
                  'Ajukan Izin/Cuti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: leaveType,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          border: InputBorder.none,
                          labelText: 'Jenis',
                          labelStyle: TextStyle(color: Color(0xFF667EEA)),
                        ),
                        items: ['izin', 'cuti']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.toUpperCase(),
                                    style: TextStyle(color: Color(0xFF2D3748)),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            leaveType = value!;
                          });
                        },
                        dropdownColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Keterangan',
                        labelStyle: TextStyle(color: Color(0xFF667EEA)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
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
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Color(0xFF667EEA),
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy').format(selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Color(0xFF667EEA),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Keterangan harus diisi'),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final response = await _api.requestLeave(
                        widget.user['id'],
                        leaveType,
                        reasonController.text,
                        tanggal: selectedDate,
                      );

                      if (response['success'] == true) {
                        _showSuccessDialog('Pengajuan berhasil dikirim!');
                      } else {
                        _showErrorDialog(response['message']);
                      }
                    } catch (e) {
                      _showErrorDialog('Error: $e');
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF667EEA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Ajukan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
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
                  color: Colors.green.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Sukses',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  minimumSize: Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
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
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  minimumSize: Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Mengerti',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (context) => ProfileDialog(
        userId: widget.user['id'],
        onLogout: () async {
          final auth = AuthService();
          await auth.logout();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        },
      ),
    );
  }

  void _manageEmployees() {
    showDialog(
      context: context,
      builder: (context) => EmployeeCRUDDialog(
        onEmployeeUpdated: () {
          _loadEmployees();
          _loadAttendanceReport();
        },
      ),
    );
  }

  void _applyReportFilters() {
    _loadAttendanceReport();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'HRD Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.dashboard, size: 24),
                    text: 'Dashboard',
                  ),
                  Tab(
                    icon: Icon(Icons.assessment, size: 24),
                    text: 'Laporan',
                  ),
                ],
                indicatorColor: Color(0xFF667EEA),
                labelColor: Color(0xFF667EEA),
                unselectedLabelColor: Colors.grey[600],
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 20),
                splashFactory: NoSplash.splashFactory,
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    return states.contains(MaterialState.hovered)
                        ? Colors.blue.withOpacity(0.1)
                        : null;
                  },
                ),
              ),
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Icon(Icons.people, color: Colors.white),
                ),
                onPressed: _manageEmployees,
                tooltip: 'Kelola Karyawan',
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                onPressed: _showProfile,
                tooltip: 'Profile',
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFF7FAFC),
              ],
            ),
          ),
          child: TabBarView(
            children: [
              // Tab 1: Dashboard
              SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with time and date
                    Container(
                      padding: EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF667EEA).withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy')
                                .format(_currentTime),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            DateFormat('HH:mm:ss').format(_currentTime),
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.badge,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'HRD: ${widget.user['nama']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Attendance buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading || _hasCheckedIn ? null : _checkIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 22,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child: Icon(
                                      Icons.login,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ABSEN MASUK',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _hasCheckedIn
                                              ? 'Sudah check-in'
                                              : 'Belum check-in',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color:
                                                Colors.black.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading || !_hasCheckedIn || _hasCheckedOut
                                      ? null
                                      : _checkOut,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF9800),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 22,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ABSEN PULANG',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _hasCheckedOut
                                              ? 'Sudah check-out'
                                              : 'Belum check-out',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color:
                                                Colors.black.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Leave request button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF667EEA).withOpacity(0.2),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _requestLeave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: Icon(
                                Icons.beach_access,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IZIN / CUTI',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ajukan izin atau cuti',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // HRD's attendance history
                    AttendanceHistoryWidget(userId: widget.user['id']),
                  ],
                ),
              ),

              // Tab 2: Laporan
              SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filters
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                color: Color(0xFF667EEA),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Filter Laporan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: DropdownButtonFormField<int?>(
                              value: _selectedEmployeeFilter,
                              decoration: InputDecoration(
                                labelText: 'Pilih Karyawan',
                                labelStyle: TextStyle(color: Color(0xFF667EEA)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'Semua Karyawan',
                                    style: TextStyle(color: Color(0xFF2D3748)),
                                  ),
                                ),
                                ..._employees.map((employee) {
                                  return DropdownMenuItem(
                                    value: employee.id,
                                    child: Text(
                                      employee.nama,
                                      style:
                                          TextStyle(color: Color(0xFF2D3748)),
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedEmployeeFilter = value;
                                });
                              },
                              dropdownColor: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dari Tanggal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _startDateFilter ??
                                              DateTime.now(),
                                          firstDate: DateTime.now()
                                              .subtract(Duration(days: 365)),
                                          lastDate: DateTime.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: Color(0xFF667EEA),
                                                  onPrimary: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _startDateFilter = date;
                                          });
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _startDateFilter != null
                                                  ? DateFormat('dd MMM yyyy')
                                                      .format(_startDateFilter!)
                                                  : 'Pilih tanggal',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2D3748),
                                              ),
                                            ),
                                            Icon(
                                              Icons.calendar_today,
                                              color: Color(0xFF667EEA),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sampai Tanggal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _endDateFilter ?? DateTime.now(),
                                          firstDate: DateTime.now()
                                              .subtract(Duration(days: 365)),
                                          lastDate: DateTime.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: ThemeData.light().copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: Color(0xFF667EEA),
                                                  onPrimary: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (date != null) {
                                          setState(() {
                                            _endDateFilter = date;
                                          });
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _endDateFilter != null
                                                  ? DateFormat('dd MMM yyyy')
                                                      .format(_endDateFilter!)
                                                  : 'Pilih tanggal',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2D3748),
                                              ),
                                            ),
                                            Icon(
                                              Icons.calendar_today,
                                              color: Color(0xFF667EEA),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
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
                            child: ElevatedButton(
                              onPressed: _applyReportFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Terapkan Filter',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Attendance report
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.assessment,
                                color: Color(0xFF667EEA),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Laporan Presensi Karyawan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          _attendanceReport.isEmpty
                              ? Container(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox,
                                        size: 60,
                                        color: Colors.grey[300],
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Tidak ada data presensi',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Coba gunakan filter yang berbeda',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: DataTable(
                                      columnSpacing: 32,
                                      horizontalMargin: 20,
                                      headingRowHeight: 60,
                                      dataRowHeight: 60,
                                      headingTextStyle: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                        fontSize: 14,
                                      ),
                                      dataTextStyle: TextStyle(
                                        color: Color(0xFF4A5568),
                                        fontSize: 13,
                                      ),
                                      columns: [
                                        DataColumn(
                                          label: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text('Tanggal'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text('Nama'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text('Jabatan'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text('Check In'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text('Check Out'),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Text('Status'),
                                          ),
                                        ),
                                      ],
                                      rows: _attendanceReport.map((record) {
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Text(
                                                  DateFormat('dd-MM-yyyy')
                                                      .format(record.tanggal),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(record.nama ?? '-'),
                                            ),
                                            DataCell(
                                              Text(record.jabatan ?? '-'),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  record.checkIn ?? '-',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  record.checkOut ?? '-',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green[700],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: record.status ==
                                                          'hadir'
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : record.status == 'izin'
                                                          ? Colors.orange
                                                              .withOpacity(0.1)
                                                          : Colors.red
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  record.status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: record.status ==
                                                            'hadir'
                                                        ? Colors.green[700]
                                                        : record.status ==
                                                                'izin'
                                                            ? Colors.orange[700]
                                                            : Colors.red[700],
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
