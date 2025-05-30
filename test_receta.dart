import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/models/receta.dart';
import 'lib/services/receta_service.dart';

void main() async {
  // Inicializar Supabase - reemplazar con tus credenciales correctas
  WidgetsFlutterBinding.ensureInitialized();  await Supabase.initialize(
    url: 'https://tlpmxypeiiaanzknkttf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRscG14eXBlaWlhYW56a25rdHRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM0NDMwOTUsImV4cCI6MjAyOTAxOTA5NX0.5yPF9NmZrDxECwJQBgJmhNQ_qv1JlILXOQP-1Ke9hDc',
  );

  // Probar la creación de una receta sin cantidades
  try {
    final recetaService = RecetaService();
    
    // Primero necesitamos verificar algunas materias primas existentes
    print('Verificando materias primas existentes...');
    final materiaPrimaIds = await _obtenerMateriasPrimasExistentes();
    if (materiaPrimaIds.isEmpty) {
      print('⚠️ No hay materias primas disponibles para crear una receta');
      return;
    }
    
    print('Usando materias primas con IDs: $materiaPrimaIds');
    
    // Crear una receta con IDs de materias primas pero sin cantidades
    final receta = Receta(
      idsMps: materiaPrimaIds,
    );
    
    print('Creando receta...');
    final recetaCreada = await recetaService.crear(receta);
    print('✅ Receta creada exitosamente con ID: ${recetaCreada.id}');
    print('IDs de materias primas: ${recetaCreada.idsMps}');
    print('Cantidades: ${recetaCreada.cantidades}');
    
    // Obtener detalles de la receta
    final detalles = await recetaService.obtenerDetallesReceta(recetaCreada.id!);
    print('Detalles de la receta:');
    print('  - ID: ${detalles['receta'].id}');
    print('  - Ingredientes:');
    
    final materiasPrimas = detalles['materiasPrimas'] as List<Map<String, dynamic>>;
    for (var mp in materiasPrimas) {
      print('    * ${mp['nombre']} (cantidad: ${mp['cantidad']})');
    }
    
  } catch (e) {
    print('❌ Error en la prueba: $e');
  }

  // Terminar la aplicación
  print('Terminado');
}
