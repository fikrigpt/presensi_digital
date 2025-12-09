import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/api_service.dart';
import '../models/attendance.dart';

class AttendanceHistoryWidget extends StatefulWidget {
  final int userId;

  AttendanceHistoryWidget({required this.userId});

  @override
  _AttendanceHistoryWidgetState createState() =>
      _AttendanceHistoryWidgetState();
}

class _AttendanceHistoryWidgetState extends State<AttendanceHistoryWidget> {
  final ApiService _api = ApiService();
  late Future<List<Attendance>> _attendanceHistory;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  @override
  void initState() {
    super.initState();
    _attendanceHistory = _api.getAttendanceHistory(widget.userId);
  }

  void _refreshHistory() {
    setState(() {
      _attendanceHistory = _api.getAttendanceHistory(
        widget.userId,
        startDate: _startDateFilter,
        endDate: _endDateFilter,
      );
    });
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
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
                        Icons.history,
                        size: 22,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Riwayat Absensi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF667EEA),
                      size: 22,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          DateTime? tempStartDate = _startDateFilter;
                          DateTime? tempEndDate = _endDateFilter;

                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Dialog(
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
                                          color: Color(0xFF667EEA)
                                              .withOpacity(0.1),
                                        ),
                                        child: Icon(
                                          Icons.filter_alt,
                                          size: 32,
                                          color: Color(0xFF667EEA),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Filter Riwayat',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                initialDate: tempStartDate ??
                                                    DateTime.now(),
                                                firstDate: DateTime.now()
                                                    .subtract(
                                                        Duration(days: 365)),
                                                lastDate: DateTime.now(),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: ThemeData.light()
                                                        .copyWith(
                                                      colorScheme:
                                                          ColorScheme.light(
                                                        primary:
                                                            Color(0xFF667EEA),
                                                        onPrimary: Colors.white,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (date != null) {
                                                setState(() {
                                                  tempStartDate = date;
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    tempStartDate != null
                                                        ? DateFormat(
                                                                'dd MMM yyyy')
                                                            .format(
                                                                tempStartDate!)
                                                        : 'Pilih tanggal',
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
                                          SizedBox(height: 20),
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
                                                initialDate: tempEndDate ??
                                                    DateTime.now(),
                                                firstDate: DateTime.now()
                                                    .subtract(
                                                        Duration(days: 365)),
                                                lastDate: DateTime.now(),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: ThemeData.light()
                                                        .copyWith(
                                                      colorScheme:
                                                          ColorScheme.light(
                                                        primary:
                                                            Color(0xFF667EEA),
                                                        onPrimary: Colors.white,
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (date != null) {
                                                setState(() {
                                                  tempEndDate = date;
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    tempEndDate != null
                                                        ? DateFormat(
                                                                'dd MMM yyyy')
                                                            .format(
                                                                tempEndDate!)
                                                        : 'Pilih tanggal',
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
                                      SizedBox(height: 32),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                      color: Colors.grey[300]!),
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
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  tempStartDate = null;
                                                  tempEndDate = null;
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                              ),
                                              child: Text(
                                                'Reset',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _startDateFilter =
                                                      tempStartDate;
                                                  _endDateFilter = tempEndDate;
                                                });
                                                Navigator.pop(context);
                                                _refreshHistory();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Color(0xFF667EEA),
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                'Terapkan',
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
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Filter summary
            if (_startDateFilter != null || _endDateFilter != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF667EEA).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF667EEA).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 16,
                      color: Color(0xFF667EEA),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filter: ${_startDateFilter != null ? 'Dari ${_formatDate(_startDateFilter)}' : ''}${_startDateFilter != null && _endDateFilter != null ? ' - ' : ''}${_endDateFilter != null ? 'Sampai ${_formatDate(_endDateFilter)}' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _startDateFilter = null;
                          _endDateFilter = null;
                        });
                        _refreshHistory();
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            FutureBuilder<List<Attendance>>(
              future: _attendanceHistory,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF667EEA),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Memuat riwayat...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Gagal memuat riwayat',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Silakan coba lagi nanti',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat absensi',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Data absensi akan muncul di sini',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final history = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final record = history[index];
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
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: record.status == 'hadir'
                                    ? [Colors.green[100]!, Colors.green[50]!]
                                    : record.status == 'izin'
                                        ? [
                                            Colors.orange[100]!,
                                            Colors.orange[50]!
                                          ]
                                        : [Colors.red[100]!, Colors.red[50]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('dd').format(record.tanggal),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: record.status == 'hadir'
                                          ? Colors.green[800]
                                          : record.status == 'izin'
                                              ? Colors.orange[800]
                                              : Colors.red[800],
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM').format(record.tanggal),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: record.status == 'hadir'
                                          ? Colors.green[600]
                                          : record.status == 'izin'
                                              ? Colors.orange[600]
                                              : Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE').format(record.tanggal),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMMM yyyy')
                                    .format(record.tanggal),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              if (record.checkIn != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.login,
                                      size: 14,
                                      color: Colors.green[600],
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Masuk: ${record.checkIn}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              if (record.checkOut != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      size: 14,
                                      color: Colors.blue[600],
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Pulang: ${record.checkOut}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              if (record.keterangan != null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.note_outlined,
                                      size: 14,
                                      color: Colors.orange[600],
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Keterangan: ${record.keterangan}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: record.status == 'hadir'
                                  ? Colors.green.withOpacity(0.1)
                                  : record.status == 'izin'
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record.status.toUpperCase(),
                              style: TextStyle(
                                color: record.status == 'hadir'
                                    ? Colors.green[800]
                                    : record.status == 'izin'
                                        ? Colors.orange[800]
                                        : Colors.red[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
