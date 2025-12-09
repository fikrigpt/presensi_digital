class Attendance {
  final int id;
  final int userId;
  final DateTime tanggal;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? keterangan;
  final String? nama;
  final String? jabatan;

  Attendance({
    required this.id,
    required this.userId,
    required this.tanggal,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.keterangan,
    this.nama,
    this.jabatan,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['user_id'],
      tanggal: DateTime.parse(json['tanggal']),
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      status: json['status'],
      keterangan: json['keterangan'],
      nama: json['nama'],
      jabatan: json['jabatan'],
    );
  }
}
