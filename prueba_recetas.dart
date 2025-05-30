import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/models/receta.dart';
import 'lib/services/receta_service.dart';

// Función para obtener IDs de materias primas existentes
Future<List<int>> _obtenerMateriasPrimasExistentes() async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase.from('Materia_prima').select('id').limit(3);
    
    if (response != null && response.isNotEmpty) {
      return (response as List).map((item) => (item['id'] as num).toInt()).toList();
    }
    return [];
  } catch (e) {
    print('Error al obtener materias primas: $e');
    return [];
  }
}

void main() async {
  // Inicializar Supabase
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tlpmxypeiiaanzknkttf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRscG14eXBlaWlhYW56a25rdHRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM0NDMwOTUsImV4cCI6MjAyOTAxOTA5NX0.5yPF9NmZrDxECwJQBgJmhNQ_qv1JlILXOQP-1Ke9hDc',
  );

  print('-------------------------------------');
  print('🔍 PRUEBA DE RECETAS SIN CANTIDADES');
  print('-------------------------------------');

  // Probar la creación de una receta sin cantidades
  try {
    final recetaService = RecetaService();
    
    // Paso 1: Verificar materias primas existentes
    print('\n1️⃣ Verificando materias primas existentes...');
    final materiaPrimaIds = await _obtenerMateriasPrimasExistentes();
    if (materiaPrimaIds.isEmpty) {
      print('⚠️ No hay materias primas disponibles para crear una receta');
      return;
    }
    print('✅ Materias primas encontradas con IDs: $materiaPrimaIds');
    
    // Paso 2: Crear una receta SIN cantidades
    print('\n2️⃣ Creando receta SIN cantidades...');
    final receta = Receta(
      idsMps: materiaPrimaIds,
      // No se proporcionan cantidades
    );
    
    final recetaCreada = await recetaService.crear(receta);
    print('✅ Receta creada exitosamente con ID: ${recetaCreada.id}');
    print('📋 IDs de materias primas: ${recetaCreada.idsMps}');
    print('📊 Cantidades internas (no almacenadas en DB): ${recetaCreada.cantidades}');
    
    // Paso 3: Obtener detalles de la receta
    print('\n3️⃣ Obteniendo detalles de la receta creada...');
    final detalles = await recetaService.obtenerDetallesReceta(recetaCreada.id!);
    
    print('📝 Detalles de la receta:');
    print('  • ID: ${detalles['receta'].id}');
    print('  • Ingredientes:');
    
    final materiasPrimas = detalles['materiasPrimas'] as List<dynamic>;
    for (var mp in materiasPrimas) {
      print('    → ${mp['nombre']} (cantidad: ${mp['cantidad']})');
    }

    // Paso 4: Verificar que las cantidades se generaron correctamente 
    print('\n4️⃣ Verificando cantidades generadas...');
    if (materiasPrimas.every((mp) => mp['cantidad'] == 1)) {
      print('✅ Todas las cantidades se generaron correctamente con valor 1');
    } else {
      print('❌ Las cantidades no se generaron correctamente');
      print('Valores encontrados: ${materiasPrimas.map((mp) => mp['cantidad'])}');
    }
    
  } catch (e) {
    print('\n❌ ERROR EN LA PRUEBA:');
    print(e);
  }

  print('\n-------------------------------------');
  print('🏁 PRUEBA FINALIZADA');
  print('-------------------------------------');
}
