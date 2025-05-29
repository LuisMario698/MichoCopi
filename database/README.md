# Base de Datos - Módulo de Ventas MichoCopi

## Instrucciones de Instalación

### 1. Ejecutar el Esquema de Ventas

Para implementar el módulo de ventas, debes ejecutar el archivo `supabase_ventas_schema.sql` en tu consola de Supabase.

**Pasos:**

1. Ve a tu proyecto de Supabase en https://supabase.com/dashboard
2. Navega a **SQL Editor** en el panel izquierdo
3. Crea una nueva consulta
4. Copia y pega todo el contenido del archivo `supabase_ventas_schema.sql`
5. Ejecuta la consulta

### 2. Verificar la Instalación

Después de ejecutar el script, verifica que se crearon las siguientes estructuras:

#### Tablas:
- `"Ventas"` - Modificada con nuevas columnas
- `"Venta_Detalles"` - Nueva tabla para detalles de venta

#### Funciones:
- `calcular_subtotal()`
- `actualizar_total_venta()`
- `obtener_ventas_filtradas()`
- `obtener_estadisticas_ventas()`

#### Vistas:
- `"Ventas_Resumen"`
- `"Productos_Mas_Vendidos"`

#### Triggers:
- `trigger_calcular_subtotal`
- `trigger_actualizar_total_venta`
- `update_ventas_updated_at`

### 3. Consulta de Verificación

Ejecuta esta consulta para verificar que todo se instaló correctamente:

```sql
-- Verificar que las tablas se crearon correctamente
SELECT 'Ventas' as tabla, count(*) as registros FROM public."Ventas"
UNION ALL
SELECT 'Venta_Detalles' as tabla, count(*) as registros FROM public."Venta_Detalles";

-- Verificar vistas
SELECT * FROM public."Ventas_Resumen" LIMIT 5;
SELECT * FROM public."Productos_Mas_Vendidos" LIMIT 5;

-- Probar funciones
SELECT public.obtener_estadisticas_ventas('mes');
```

### 4. Políticas de Seguridad

El script incluye políticas RLS (Row Level Security) que permiten a todos los usuarios autenticados:
- Ver todas las ventas
- Crear nuevas ventas
- Actualizar ventas existentes

### 5. Estructura de Datos

#### Tabla "Ventas":
- `id` - ID único de la venta
- `cliente` - Nombre del cliente (opcional)
- `total` - Total calculado automáticamente
- `fecha` - Fecha y hora de la venta
- `estado` - Estado: 'Completada', 'Pendiente', 'Cancelada'
- `usuario_id` - ID del usuario que registró la venta
- `created_at` / `updated_at` - Timestamps

#### Tabla "Venta_Detalles":
- `id` - ID único del detalle
- `venta_id` - Referencia a la venta
- `producto_id` - Referencia al producto
- `nombre_producto` - Nombre del producto al momento de la venta
- `cantidad` - Cantidad vendida
- `precio_unitario` - Precio al momento de la venta
- `subtotal` - Calculado automáticamente (cantidad × precio)
- `created_at` - Timestamp de creación

## Características del Sistema

### ✅ Funcionalidades Implementadas:

1. **Gestión de Ventas Completa**
   - Búsqueda de productos en tiempo real
   - Carrito de compras interactivo
   - Cálculo automático de totales
   - Información de cliente opcional

2. **Integración con Base de Datos**
   - Inserción automática de ventas y detalles
   - Actualización automática de stock de productos
   - Cálculos automáticos mediante triggers
   - Políticas de seguridad configuradas

3. **Interfaz de Usuario**
   - Modal profesional con diseño moderno
   - Colores de marca MichoCopi consistentes
   - Estados de carga y mensajes de feedback
   - Búsqueda y filtrado de productos

4. **Características Técnicas**
   - Manejo de errores robusto
   - Transacciones de base de datos
   - Validaciones de stock
   - Logs detallados para debugging

### 🎯 Próximas Mejoras Sugeridas:

- [ ] Reportes de ventas con gráficos
- [ ] Exportación a PDF/Excel
- [ ] Sistema de descuentos
- [ ] Gestión de devoluciones
- [ ] Integración con impresoras de tickets
- [ ] Sincronización offline

## Soporte

Si encuentras algún problema durante la instalación:

1. Verifica que tienes permisos de administrador en Supabase
2. Asegúrate de que las tablas `"Productos"` y `"Usuarios"` ya existen
3. Revisa los logs de error en la consola de Supabase
4. Contacta al equipo de desarrollo con los detalles del error

---

**Fecha de Última Actualización:** 27 de mayo de 2025  
**Versión del Sistema:** 1.0.0  
**Autor:** GitHub Copilot para MichoCopi
