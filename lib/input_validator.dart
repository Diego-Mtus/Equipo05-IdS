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


   // Validar Teléfono
  static String? validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese su número de teléfono';
    }

    // Solo números
    final numberRegExp = RegExp(r'^\d+$');
    if (!numberRegExp.hasMatch(value.trim())) {
      return 'El número de teléfono debe contener solo números';
    }

    // Ejemplo: 9 dígitos (ajusta si quieres otra longitud)
    if (value.trim().length != 9) {
      return 'El número de teléfono debe tener 9 dígitos';
    }

    return null;
  }
}