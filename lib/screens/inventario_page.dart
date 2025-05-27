import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Inventario',
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Implementar reporte de inventario
          },
          icon: const Icon(Icons.download),
          label: const Text('Exportar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implementar ajuste de inventario
          },
          icon: const Icon(Icons.edit),
          label: const Text('Ajustar Stock'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC2185B),
            foregroundColor: Colors.white,
          ),
        ),
      ],
      child: Column(
        children: [
          // Resumen de inventario
          Row(
            children: [
              Expanded(
                child: _buildInventoryCard(
                  'Total Productos',
                  '1,234',
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryCard(
                  'Stock Bajo',
                  '23',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryCard(
                  'Sin Stock',
                  '5',
                  Icons.remove_circle,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInventoryCard(
                  'Valor Total',
                  '\$45,678',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filtros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar en inventario...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: 'Todos',
                    items:
                        ['Todos', 'Stock bajo', 'Sin stock', 'Stock normal']
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      // TODO: Implementar filtro
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tabla de inventario
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Producto',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'SKU',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Stock Actual',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Stock Mínimo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Precio',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Estado',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 50, // Placeholder
                      itemBuilder: (context, index) {
                        final stock = 50 - index;
                        final minStock = 10;
                        final status =
                            stock == 0
                                ? 'Sin stock'
                                : stock <= minStock
                                ? 'Stock bajo'
                                : 'Normal';
                        final statusColor =
                            stock == 0
                                ? Colors.red
                                : stock <= minStock
                                ? Colors.orange
                                : Colors.green;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text('Producto ${index + 1}'),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('PRD${1000 + index}'),
                              ),
                              Expanded(flex: 1, child: Text('$stock')),
                              Expanded(flex: 1, child: Text('$minStock')),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '\$${(10 + index * 2).toStringAsFixed(2)}',
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
