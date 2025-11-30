

class Usuario {
  String nombre;
  String correo;
  String telefono;

  Usuario({
    required this.nombre,
    required this.correo,
    required this.telefono,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'correo': correo,
    'nMatricula': telefono,
  };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    nombre: json['nombre'],
    correo: json['correo'],
    telefono: json['nMatricula'],
  );
}


