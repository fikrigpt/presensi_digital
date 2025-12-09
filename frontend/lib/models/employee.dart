class Employee {
  final int id;
  final String username;
  final String nama;
  final int? umur;
  final String? domisili;
  final String? jabatan;
  final String? foto;

  Employee({
    required this.id,
    required this.username,
    required this.nama,
    this.umur,
    this.domisili,
    this.jabatan,
    this.foto,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      username: json['username'],
      nama: json['nama'],
      umur: json['umur'],
      domisili: json['domisili'],
      jabatan: json['jabatan'],
      foto: json['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama': nama,
      'umur': umur,
      'domisili': domisili,
      'jabatan': jabatan,
      'foto': foto,
    };
  }
}
