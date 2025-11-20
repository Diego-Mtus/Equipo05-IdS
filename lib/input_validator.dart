class InputValidator {
  // Validar Nombre
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su nombre';
    }
    if (value.trim().length < 3) {
      return 'El nombre es muy corto';
    }
    // Regex para asegurar que solo sean letras y espacios (incluye tildes)
    final nameRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegExp.hasMatch(value)) {
      return 'Ingrese un nombre válido (solo letras)';
    }
    return null;
  }

  // Validar Correo UdeC
  static String? validateUdecEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su correo';
    }
    // Primero verificamos formato general de correo para evitar errores raros
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Formato de correo inválido';
    }

    if (!value.trim().toLowerCase().endsWith('@udec.cl')) {
      return 'Debe usar correo institucional (@udec.cl)';
    }
    return null;
  }


  // Validar Matrícula
  static String? validateMatricula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su número de matrícula';
    }
    // Verificamos que SOLO contenga números
    final numberRegExp = RegExp(r'^\d+$');
    if (!numberRegExp.hasMatch(value)) {
      return 'La matrícula debe contener solo números';
    }
    // Verificamos longitud exacta
    if (value.trim().length != 10) {
      return 'La matrícula debe tener 10 dígitos';
    }
    return null;
  }
}