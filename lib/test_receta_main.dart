import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/receta.dart';
import 'services/receta_service.dart';

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

void main() {
  runApp(const TestRecetaApp());
}

class TestRecetaApp extends StatelessWidget {
  const TestRecetaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test de Recetas',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: const TestRecetaPage(),
    );
  }
}

class TestRecetaPage extends StatefulWidget {
  const TestRecetaPage({Key? key}) : super(key: key);

  @override
  _TestRecetaPageState createState() => _TestRecetaPageState();
}

class _TestRecetaPageState extends State<TestRecetaPage> {
  bool _isLoading = true;
  String _testOutput = "Inicializando prueba...";
  List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _inicializarSupabase();
  }

  Future<void> _inicializarSupabase() async {
    _addLog("Inicializando Supabase...");
    try {
      await Supabase.initialize(
        url: 'https://tlpmxypeiiaanzknkttf.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRscG14eXBlaWlhYW56a25rdHRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM0NDMwOTUsImV4cCI6MjAyOTAxOTA5NX0.5yPF9NmZrDxECwJQBgJmhNQ_qv1JlILXOQP-1Ke9hDc',
      );
      _addLog("✅ Supabase inicializado correctamente");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _addLog("❌ Error al inicializar Supabase: $e");
      setState(() {
        _testOutput = "Error al inicializar: $e";
        _isLoading = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.add(message);
      _testOutput = _logMessages.join('\n');
    });
  }

  Future<void> _ejecutarPrueba() async {
    setState(() {
      _isLoading = true;
      _logMessages.clear();
      _testOutput = "Ejecutando prueba...";
    });

    _addLog("-------------------------------------");
    _addLog("🔍 PRUEBA DE RECETAS SIN CANTIDADES");
    _addLog("-------------------------------------");

    try {
      final recetaService = RecetaService();
      
      // Paso 1: Verificar materias primas existentes
      _addLog("\n1️⃣ Verificando materias primas existentes...");
      final materiaPrimaIds = await _obtenerMateriasPrimasExistentes();
      if (materiaPrimaIds.isEmpty) {
        _addLog("⚠️ No hay materias primas disponibles para crear una receta");
        setState(() {
          _isLoading = false;
        });
        return;
      }
      _addLog("✅ Materias primas encontradas con IDs: $materiaPrimaIds");
      
      // Paso 2: Crear una receta SIN cantidades
      _addLog("\n2️⃣ Creando receta SIN cantidades...");
      final receta = Receta(
        idsMps: materiaPrimaIds,
        // No se proporcionan cantidades
      );
      
      final recetaCreada = await recetaService.crear(receta);
      _addLog("✅ Receta creada exitosamente con ID: ${recetaCreada.id}");
      _addLog("📋 IDs de materias primas: ${recetaCreada.idsMps}");
      _addLog("📊 Cantidades internas (no almacenadas en DB): ${recetaCreada.cantidades}");
      
      // Paso 3: Obtener detalles de la receta
      _addLog("\n3️⃣ Obteniendo detalles de la receta creada...");
      final detalles = await recetaService.obtenerDetallesReceta(recetaCreada.id!);
      
      _addLog("📝 Detalles de la receta:");
      _addLog("  • ID: ${detalles['receta'].id}");
      _addLog("  • Ingredientes:");
      
      final materiasPrimas = detalles['materiasPrimas'] as List<dynamic>;
      for (var mp in materiasPrimas) {
        _addLog("    → ${mp['nombre']} (cantidad: ${mp['cantidad']})");
      }

      // Paso 4: Verificar que las cantidades se generaron correctamente 
      _addLog("\n4️⃣ Verificando cantidades generadas...");
      if (materiasPrimas.every((mp) => mp['cantidad'] == 1)) {
        _addLog("✅ Todas las cantidades se generaron correctamente con valor 1");
      } else {
        _addLog("❌ Las cantidades no se generaron correctamente");
        _addLog("Valores encontrados: ${materiasPrimas.map((mp) => mp['cantidad'])}");
      }
      
    } catch (e) {
      _addLog("\n❌ ERROR EN LA PRUEBA:");
      _addLog(e.toString());
    }

    _addLog("\n-------------------------------------");
    _addLog("🏁 PRUEBA FINALIZADA");
    _addLog("-------------------------------------");
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prueba de Recetas'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prueba de creación de recetas sin cantidades',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _ejecutarPrueba,
              icon: Icon(Icons.play_arrow),
              label: Text('Ejecutar prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Resultado de la prueba:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                  : SingleChildScrollView(
                      child: Text(
                        _testOutput,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
