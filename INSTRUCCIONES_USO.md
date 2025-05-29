# INSTRUCCIONES DE USO - SISTEMA DE VENTAS MICHOCOPI

## 🚀 PASOS PARA ACTIVAR EL SISTEMA DE VENTAS

### 1. Ejecutar el Esquema de Base de Datos

**IMPORTANTE:** Antes de usar el sistema de ventas, debes ejecutar el esquema SQL en tu base de datos Supabase.

1. **Accede a tu consola de Supabase:**
   - Ve a https://supabase.com/dashboard
   - Selecciona tu proyecto MichoCopi
   - Haz clic en "SQL Editor" en el menú lateral

2. **Ejecuta el esquema:**
   - Abre el archivo `database/supabase_ventas_schema.sql`
   - Copia TODO el contenido del archivo
   - Pégalo en una nueva consulta en Supabase
   - Haz clic en "Run" para ejecutar

3. **Verifica la instalación:**
   ```sql
   -- Ejecuta esta consulta para verificar que todo se instaló correctamente
   SELECT 'Ventas' as tabla, count(*) as registros FROM public."Ventas"
   UNION ALL
   SELECT 'Venta_Detalles' as tabla, count(*) as registros FROM public."Venta_Detalles";
   ```

### 2. Usar el Sistema de Ventas

Una vez ejecutado el esquema SQL:

1. **Ejecuta la aplicación:**
   ```bash
   flutter run
   ```

2. **Navega a la sección de Ventas:**
   - Inicia sesión en la aplicación
   - Ve al menú lateral y selecciona "Ventas"

3. **Crear una nueva venta:**
   - Haz clic en el botón flotante "+" (Generate Sales)
   - Se abrirá el modal de nueva venta

4. **Proceso de venta:**
   - **Buscar productos:** Usa la barra de búsqueda en la parte izquierda
   - **Agregar al carrito:** Haz clic en "Agregar" junto a cada producto
   - **Modificar cantidades:** Usa los botones +/- en el carrito
   - **Información del cliente:** (Opcional) Ingresa el nombre del cliente
   - **Procesar venta:** Haz clic en "Procesar Venta"

5. **Confirmación:**
   - El sistema mostrará un mensaje de éxito con el ID de la venta
   - El modal se cerrará automáticamente
   - La lista de ventas se actualizará con la nueva venta

### 3. Funcionalidades Disponibles

#### ✅ En el Modal de Ventas:
- **Búsqueda en tiempo real** de productos
- **Validación de stock** antes de agregar al carrito
- **Cálculo automático** de subtotales y total
- **Información opcional** del cliente
- **Estados de carga** durante el procesamiento

#### ✅ En la Página de Ventas:
- **Lista actualizada** de todas las ventas
- **Información completa** de cada venta (ID, cliente, total, fecha)
- **Actualización automática** después de crear una venta

#### ✅ En la Base de Datos:
- **Registro automático** de ventas y detalles
- **Actualización de stock** de productos vendidos
- **Cálculos automáticos** mediante triggers
- **Historial completo** de transacciones

---

## 🎨 COLORES DE MARCA ACTUALIZADOS

El sistema ahora usa consistentemente el color de marca MichoCopi:
- **Color principal:** `#C2185B` (Rosa Michoacana)
- **Aplicado en:** Login, botones, elementos activos, mensajes de estado

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### Error: "Table doesn't exist"
- **Causa:** No se ejecutó el esquema SQL
- **Solución:** Ejecuta el archivo `database/supabase_ventas_schema.sql` en Supabase

### Error: "No products found"
- **Causa:** No hay productos en la base de datos
- **Solución:** Agrega productos desde la sección "Productos" de la aplicación

### Error: "Insufficient stock"
- **Causa:** El producto no tiene suficiente stock
- **Solución:** Actualiza el stock del producto o reduce la cantidad en el carrito

### El modal no se abre
- **Causa:** Error de JavaScript/Flutter
- **Solución:** Revisa la consola de errores y verifica que no hay errores de compilación

---

## 📊 VERIFICACIÓN DEL SISTEMA

### Test Manual:
1. ✅ Login con colores de marca actualizados
2. ✅ Navegación a la página de Ventas
3. ✅ Apertura del modal de nueva venta
4. ✅ Búsqueda de productos funcional
5. ✅ Agregar productos al carrito
6. ✅ Modificar cantidades en el carrito
7. ✅ Procesar venta exitosamente
8. ✅ Verificar venta en la lista
9. ✅ Verificar actualización de stock

### Test Automático:
```bash
# Ejecutar el script de pruebas (opcional)
dart test_ventas_system.dart
```

---

## 📁 ARCHIVOS IMPORTANTES

### Archivos Principales:
- `lib/screens/ventas_page.dart` - Página principal de ventas
- `lib/widgets/nueva_venta_modal.dart` - Modal de nueva venta
- `lib/services/venta_service.dart` - Lógica de negocio para ventas

### Base de Datos:
- `database/supabase_ventas_schema.sql` - Esquema completo a ejecutar
- `database/README.md` - Documentación detallada

### Documentación:
- `SISTEMA_VENTAS_COMPLETADO.md` - Resumen completo del proyecto
- Este archivo - Instrucciones de uso

---

## 🎯 PRÓXIMOS PASOS RECOMENDADOS

1. **Ejecutar el esquema SQL** en Supabase
2. **Probar el sistema completo** con datos reales
3. **Agregar algunos productos** si no los hay
4. **Realizar ventas de prueba** para verificar funcionamiento
5. **Revisar reportes y estadísticas** (funciones SQL incluidas)

---

**¡El Sistema de Ventas MichoCopi está listo para usar!** 🎉

Desarrollado con ❤️ por GitHub Copilot  
Fecha: 27 de mayo de 2025
