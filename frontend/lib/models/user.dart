class User {
  final int id;
  final String username;
  final String role;
  final String nama;
  final int? umur;
  final String? domisili;
  final String? jabatan;
  final String? foto;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.nama,
    this.umur,
    this.domisili,
    this.jabatan,
    this.foto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      role: json['role'],
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
      'role': role,
      'nama': nama,
      'umur': umur,
      'domisili': domisili,
      'jabatan': jabatan,
      'foto': foto,
    };
  }
}
