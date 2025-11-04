

class Usuario {
  String nombre;
  String correo;
  String nMatricula;

  Usuario({
    required this.nombre,
    required this.correo,
    required this.nMatricula,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'correo': correo,
    'nMatricula': nMatricula,
  };

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    nombre: json['nombre'],
    correo: json['correo'],
    nMatricula: json['nMatricula'],
  );
}


