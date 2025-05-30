# Modificación: Eliminar campo de fecha de caducidad y actualizar implementación de Receta

## Fecha: 29 de mayo de 2025

## Cambios realizados:

### 1. Eliminación del campo de fecha de caducidad
- Eliminado el campo `_fechaCaducidad` del formulario de productos
- Eliminada la función `_categoriaPermiteCaducidad`
- Eliminada la función `_seleccionarFecha()`
- Eliminadas las secciones de UI relacionadas con fecha de caducidad
- Eliminadas las validaciones de fecha en `_guardarProducto()`
- Eliminada la visualización de información de caducidad en la página de productos
- Eliminada la función `_calcularEstadoCaducidad()`

### 2. Actualización de la clase Receta
- Modificada la clase Receta para hacer las cantidades opcionales con valor predeterminado `[]`
- Actualizado el método `fromJson()` para manejar cantidades vacías
- **CORRECCIÓN:** Eliminado el campo `cantidades` del método `toJson()` y `toJsonForInsert()` ya que no existe en el esquema de la base de datos
- Las cantidades se mantienen internamente con valor 1 para conservar compatibilidad con el código existente

### 3. Ajustes en servicios y vistas
- Modificado `RecetaService.crear()` para usar el método actualizado
- Adaptado el método `obtenerDetallesReceta()` para trabajar con cantidades vacías
- Corregido `_verificarMateriasPrimasExisten()` para manejar listas vacías
- Actualizado el formulario de productos para no enviar cantidades al crear recetas

## Estado actual:
- ✅ El sistema puede crear recetas sin el campo de cantidades
- ✅ Las recetas siguen siendo compatibles con el código existente
- ✅ No se muestra información de fechas de caducidad en los productos
