-- ========================================
-- TABLAS ADICIONALES PARA SISTEMA DE REPORTES
-- Sistema MichoCopi - Optimización de Consultas
-- ========================================

-- Tabla para almacenar resúmenes diarios de ventas (mejora rendimiento)
CREATE TABLE IF NOT EXISTS ventas_diarias_resumen (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    total_ventas INTEGER DEFAULT 0,
    ingreso_total DECIMAL(10,2) DEFAULT 0.00,
    promedio_venta DECIMAL(10,2) DEFAULT 0.00,
    metodo_pago_efectivo_count INTEGER DEFAULT 0,
    metodo_pago_efectivo_total DECIMAL(10,2) DEFAULT 0.00,
    metodo_pago_tarjeta_count INTEGER DEFAULT 0,
    metodo_pago_tarjeta_total DECIMAL(10,2) DEFAULT 0.00,
    metodo_pago_transferencia_count INTEGER DEFAULT 0,
    metodo_pago_transferencia_total DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fecha)
);

-- Tabla para rankings de productos más vendidos por período
CREATE TABLE IF NOT EXISTS productos_vendidos_ranking (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL,
    periodo_tipo VARCHAR(20) NOT NULL, -- 'diario', 'semanal', 'mensual'
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    cantidad_vendida INTEGER DEFAULT 0,
    ingreso_generado DECIMAL(10,2) DEFAULT 0.00,
    ranking_posicion INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE,
    UNIQUE(producto_id, periodo_tipo, periodo_inicio, periodo_fin)
);

-- Tabla para métricas de inventario por categoría
CREATE TABLE IF NOT EXISTS inventario_metricas_categoria (
    id SERIAL PRIMARY KEY,
    categoria_id INTEGER NOT NULL,
    fecha DATE NOT NULL,
    total_productos INTEGER DEFAULT 0,
    valor_total_inventario DECIMAL(12,2) DEFAULT 0.00,
    productos_stock_bajo INTEGER DEFAULT 0,
    productos_sin_stock INTEGER DEFAULT 0,
    promedio_precio_categoria DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (categoria_id) REFERENCES categorias_productos(id) ON DELETE CASCADE,
    UNIQUE(categoria_id, fecha)
);

-- Tabla para resumen mensual de compras por proveedor
CREATE TABLE IF NOT EXISTS compras_mensuales_proveedor (
    id SERIAL PRIMARY KEY,
    proveedor_id INTEGER NOT NULL,
    año INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    total_compras INTEGER DEFAULT 0,
    monto_total DECIMAL(12,2) DEFAULT 0.00,
    promedio_compra DECIMAL(10,2) DEFAULT 0.00,
    ultima_compra_fecha DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(id) ON DELETE CASCADE,
    UNIQUE(proveedor_id, año, mes),
    CHECK (mes >= 1 AND mes <= 12)
);

-- Tabla para métricas financieras consolidadas
CREATE TABLE IF NOT EXISTS metricas_financieras_periodo (
    id SERIAL PRIMARY KEY,
    periodo_tipo VARCHAR(20) NOT NULL, -- 'diario', 'semanal', 'mensual', 'anual'
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    total_ingresos DECIMAL(12,2) DEFAULT 0.00,
    total_egresos DECIMAL(12,2) DEFAULT 0.00,
    utilidad_bruta DECIMAL(12,2) DEFAULT 0.00,
    margen_utilidad DECIMAL(5,2) DEFAULT 0.00,
    total_ventas_count INTEGER DEFAULT 0,
    total_compras_count INTEGER DEFAULT 0,
    promedio_venta DECIMAL(10,2) DEFAULT 0.00,
    promedio_compra DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(periodo_tipo, periodo_inicio, periodo_fin)
);

-- ========================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ========================================

-- Índices para ventas_diarias_resumen
CREATE INDEX IF NOT EXISTS idx_ventas_diarias_fecha ON ventas_diarias_resumen(fecha);
CREATE INDEX IF NOT EXISTS idx_ventas_diarias_total ON ventas_diarias_resumen(total_ventas DESC);

-- Índices para productos_vendidos_ranking
CREATE INDEX IF NOT EXISTS idx_productos_ranking_periodo ON productos_vendidos_ranking(periodo_tipo, periodo_inicio, periodo_fin);
CREATE INDEX IF NOT EXISTS idx_productos_ranking_cantidad ON productos_vendidos_ranking(cantidad_vendida DESC);
CREATE INDEX IF NOT EXISTS idx_productos_ranking_producto ON productos_vendidos_ranking(producto_id);

-- Índices para inventario_metricas_categoria
CREATE INDEX IF NOT EXISTS idx_inventario_categoria_fecha ON inventario_metricas_categoria(categoria_id, fecha);
CREATE INDEX IF NOT EXISTS idx_inventario_valor_total ON inventario_metricas_categoria(valor_total_inventario DESC);

-- Índices para compras_mensuales_proveedor
CREATE INDEX IF NOT EXISTS idx_compras_proveedor_periodo ON compras_mensuales_proveedor(proveedor_id, año, mes);
CREATE INDEX IF NOT EXISTS idx_compras_monto_total ON compras_mensuales_proveedor(monto_total DESC);

-- Índices para metricas_financieras_periodo
CREATE INDEX IF NOT EXISTS idx_metricas_financieras_periodo ON metricas_financieras_periodo(periodo_tipo, periodo_inicio, periodo_fin);
CREATE INDEX IF NOT EXISTS idx_metricas_utilidad ON metricas_financieras_periodo(utilidad_bruta DESC);

-- ========================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA
-- ========================================

-- Función para actualizar resumen diario de ventas
CREATE OR REPLACE FUNCTION actualizar_ventas_diarias_resumen()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar o insertar resumen para la fecha de la venta
    INSERT INTO ventas_diarias_resumen (
        fecha, 
        total_ventas, 
        ingreso_total, 
        promedio_venta,
        metodo_pago_efectivo_count,
        metodo_pago_efectivo_total,
        metodo_pago_tarjeta_count,
        metodo_pago_tarjeta_total,
        metodo_pago_transferencia_count,
        metodo_pago_transferencia_total
    )
    SELECT 
        DATE(v.fecha) as fecha,
        COUNT(*) as total_ventas,
        COALESCE(SUM(v.total), 0) as ingreso_total,
        COALESCE(AVG(v.total), 0) as promedio_venta,
        COUNT(CASE WHEN v.metodo_pago = 'efectivo' THEN 1 END) as metodo_pago_efectivo_count,
        COALESCE(SUM(CASE WHEN v.metodo_pago = 'efectivo' THEN v.total ELSE 0 END), 0) as metodo_pago_efectivo_total,
        COUNT(CASE WHEN v.metodo_pago = 'tarjeta' THEN 1 END) as metodo_pago_tarjeta_count,
        COALESCE(SUM(CASE WHEN v.metodo_pago = 'tarjeta' THEN v.total ELSE 0 END), 0) as metodo_pago_tarjeta_total,
        COUNT(CASE WHEN v.metodo_pago = 'transferencia' THEN 1 END) as metodo_pago_transferencia_count,
        COALESCE(SUM(CASE WHEN v.metodo_pago = 'transferencia' THEN v.total ELSE 0 END), 0) as metodo_pago_transferencia_total
    FROM Ventas v
    WHERE DATE(v.fecha) = DATE(COALESCE(NEW.fecha, OLD.fecha))
    GROUP BY DATE(v.fecha)
    ON CONFLICT (fecha) 
    DO UPDATE SET
        total_ventas = EXCLUDED.total_ventas,
        ingreso_total = EXCLUDED.ingreso_total,
        promedio_venta = EXCLUDED.promedio_venta,
        metodo_pago_efectivo_count = EXCLUDED.metodo_pago_efectivo_count,
        metodo_pago_efectivo_total = EXCLUDED.metodo_pago_efectivo_total,
        metodo_pago_tarjeta_count = EXCLUDED.metodo_pago_tarjeta_count,
        metodo_pago_tarjeta_total = EXCLUDED.metodo_pago_tarjeta_total,
        metodo_pago_transferencia_count = EXCLUDED.metodo_pago_transferencia_count,
        metodo_pago_transferencia_total = EXCLUDED.metodo_pago_transferencia_total,
        updated_at = NOW();
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger para ventas
CREATE OR REPLACE TRIGGER trigger_actualizar_ventas_diarias
    AFTER INSERT OR UPDATE OR DELETE ON Ventas
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_ventas_diarias_resumen();

-- Función para actualizar métricas de inventario por categoría
CREATE OR REPLACE FUNCTION actualizar_inventario_metricas_categoria()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar métricas para la categoría afectada
    INSERT INTO inventario_metricas_categoria (
        categoria_id,
        fecha,
        total_productos,
        valor_total_inventario,
        productos_stock_bajo,
        productos_sin_stock,
        promedio_precio_categoria
    )
    SELECT 
        p.id_categoria,
        CURRENT_DATE,
        COUNT(*) as total_productos,
        COALESCE(SUM(p.precio * p.stock), 0) as valor_total_inventario,
        COUNT(CASE WHEN p.stock < 10 THEN 1 END) as productos_stock_bajo,
        COUNT(CASE WHEN p.stock = 0 THEN 1 END) as productos_sin_stock,
        COALESCE(AVG(p.precio), 0) as promedio_precio_categoria
    FROM productos p
    WHERE p.id_categoria = COALESCE(NEW.id_categoria, OLD.id_categoria)
    GROUP BY p.id_categoria
    ON CONFLICT (categoria_id, fecha)
    DO UPDATE SET
        total_productos = EXCLUDED.total_productos,
        valor_total_inventario = EXCLUDED.valor_total_inventario,
        productos_stock_bajo = EXCLUDED.productos_stock_bajo,
        productos_sin_stock = EXCLUDED.productos_sin_stock,
        promedio_precio_categoria = EXCLUDED.promedio_precio_categoria,
        updated_at = NOW();
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger para productos
CREATE OR REPLACE TRIGGER trigger_actualizar_inventario_metricas
    AFTER INSERT OR UPDATE OR DELETE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_inventario_metricas_categoria();

-- ========================================
-- VISTAS PARA CONSULTAS FRECUENTES
-- ========================================

-- Vista para dashboard principal
CREATE OR REPLACE VIEW vista_dashboard_principal AS
SELECT 
    'ventas_hoy' as metrica,
    COALESCE(vdr.total_ventas, 0) as valor,
    COALESCE(vdr.ingreso_total, 0) as valor_monetario
FROM ventas_diarias_resumen vdr
WHERE vdr.fecha = CURRENT_DATE
UNION ALL
SELECT 
    'ventas_mes' as metrica,
    COALESCE(SUM(vdr.total_ventas), 0) as valor,
    COALESCE(SUM(vdr.ingreso_total), 0) as valor_monetario
FROM ventas_diarias_resumen vdr
WHERE vdr.fecha >= DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT 
    'productos_total' as metrica,
    COUNT(*) as valor,
    COALESCE(SUM(p.precio * p.stock), 0) as valor_monetario
FROM productos p
UNION ALL
SELECT 
    'productos_stock_bajo' as metrica,
    COUNT(*) as valor,
    0 as valor_monetario
FROM productos p
WHERE p.stock < 10;

-- Vista para top productos vendidos (último mes)
CREATE OR REPLACE VIEW vista_top_productos_mes AS
SELECT 
    pvr.producto_id,
    p.nombre as producto_nombre,
    pvr.cantidad_vendida,
    pvr.ingreso_generado,
    pvr.ranking_posicion
FROM productos_vendidos_ranking pvr
JOIN productos p ON pvr.producto_id = p.id
WHERE pvr.periodo_tipo = 'mensual'
    AND pvr.periodo_inicio = DATE_TRUNC('month', CURRENT_DATE)
ORDER BY pvr.ranking_posicion ASC
LIMIT 10;

-- Vista para métricas financieras del mes actual
CREATE OR REPLACE VIEW vista_metricas_financieras_mes AS
SELECT 
    mfp.total_ingresos,
    mfp.total_egresos,
    mfp.utilidad_bruta,
    mfp.margen_utilidad,
    mfp.total_ventas_count,
    mfp.total_compras_count,
    mfp.promedio_venta,
    mfp.promedio_compra
FROM metricas_financieras_periodo mfp
WHERE mfp.periodo_tipo = 'mensual'
    AND mfp.periodo_inicio = DATE_TRUNC('month', CURRENT_DATE);

-- ========================================
-- FUNCIONES AUXILIARES PARA REPORTES
-- ========================================

-- Función para calcular ranking de productos vendidos
CREATE OR REPLACE FUNCTION calcular_ranking_productos_periodo(
    p_periodo_tipo VARCHAR(20),
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE(
    producto_id INTEGER,
    cantidad_vendida INTEGER,
    ingreso_generado DECIMAL(10,2),
    ranking_posicion INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH ventas_productos AS (
        SELECT 
            unnest(v.id_productos) as producto_id,
            COUNT(*) as cantidad_vendida,
            SUM(v.total) as ingreso_generado
        FROM Ventas v
        WHERE v.fecha >= p_fecha_inicio 
            AND v.fecha <= p_fecha_fin
        GROUP BY unnest(v.id_productos)
    ),
    ranking AS (
        SELECT 
            vp.producto_id,
            vp.cantidad_vendida::INTEGER,
            vp.ingreso_generado::DECIMAL(10,2),
            ROW_NUMBER() OVER (ORDER BY vp.cantidad_vendida DESC) as ranking_posicion
        FROM ventas_productos vp
    )
    SELECT r.* FROM ranking r;
END;
$$ LANGUAGE plpgsql;

-- Función para generar resumen financiero rápido
CREATE OR REPLACE FUNCTION obtener_resumen_financiero_rapido(
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE(
    total_ingresos DECIMAL(12,2),
    total_egresos DECIMAL(12,2),
    utilidad_bruta DECIMAL(12,2),
    margen_utilidad DECIMAL(5,2)
) AS $$
DECLARE
    v_ingresos DECIMAL(12,2) := 0;
    v_egresos DECIMAL(12,2) := 0;
    v_utilidad DECIMAL(12,2) := 0;
    v_margen DECIMAL(5,2) := 0;
BEGIN
    -- Calcular ingresos desde ventas
    SELECT COALESCE(SUM(vdr.ingreso_total), 0)
    INTO v_ingresos
    FROM ventas_diarias_resumen vdr
    WHERE vdr.fecha >= p_fecha_inicio AND vdr.fecha <= p_fecha_fin;
    
    -- Calcular egresos desde compras
    SELECT COALESCE(SUM(c.total), 0)
    INTO v_egresos
    FROM Compras c
    WHERE DATE(c.fecha) >= p_fecha_inicio AND DATE(c.fecha) <= p_fecha_fin;
    
    -- Calcular utilidad y margen
    v_utilidad := v_ingresos - v_egresos;
    v_margen := CASE 
        WHEN v_ingresos > 0 THEN (v_utilidad / v_ingresos) * 100 
        ELSE 0 
    END;
    
    RETURN QUERY SELECT v_ingresos, v_egresos, v_utilidad, v_margen;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- COMENTARIOS FINALES
-- ========================================

/*
NOTAS DE IMPLEMENTACIÓN:

1. Estas tablas optimizan las consultas más frecuentes del sistema de reportes
2. Los triggers mantienen los datos actualizados automáticamente
3. Las vistas proporcionan acceso rápido a métricas clave
4. Las funciones auxiliares simplifican cálculos complejos

PARA POBLAR DATOS INICIALES:
- Ejecutar triggers manualmente para datos existentes
- Usar funciones auxiliares para calcular rankings históricos
- Verificar que los índices mejoren el rendimiento

MANTENIMIENTO:
- Ejecutar VACUUM y ANALYZE periódicamente
- Monitorear el crecimiento de las tablas de métricas
- Considerar particionado para tablas grandes
*/
