-- ================================================================
-- TABLAS ADICIONALES PARA SISTEMA DE REPORTES - MichoCopi
-- ================================================================

-- 1. Tabla para almacenar resúmenes diarios de ventas (optimización)
CREATE TABLE IF NOT EXISTS resumen_ventas_diario (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    total_ventas INTEGER DEFAULT 0,
    ingreso_total DECIMAL(10,2) DEFAULT 0.00,
    promedio_venta DECIMAL(10,2) DEFAULT 0.00,
    ventas_efectivo INTEGER DEFAULT 0,
    ventas_tarjeta INTEGER DEFAULT 0,
    ventas_transferencia INTEGER DEFAULT 0,
    monto_efectivo DECIMAL(10,2) DEFAULT 0.00,
    monto_tarjeta DECIMAL(10,2) DEFAULT 0.00,
    monto_transferencia DECIMAL(10,2) DEFAULT 0.00,
    productos_vendidos INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabla para tracking de productos más vendidos
CREATE TABLE IF NOT EXISTS ranking_productos (
    id SERIAL PRIMARY KEY,
    id_producto INTEGER REFERENCES productos(id) ON DELETE CASCADE,
    periodo VARCHAR(20) NOT NULL, -- 'diario', 'semanal', 'mensual'
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    cantidad_vendida INTEGER DEFAULT 0,
    ingresos_generados DECIMAL(10,2) DEFAULT 0.00,
    posicion_ranking INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(id_producto, periodo, fecha_inicio)
);

-- 3. Tabla para histórico de precios de productos
CREATE TABLE IF NOT EXISTS historico_precios (
    id SERIAL PRIMARY KEY,
    id_producto INTEGER REFERENCES productos(id) ON DELETE CASCADE,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    motivo VARCHAR(255),
    usuario_cambio INTEGER REFERENCES usuarios(id),
    fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tabla para movimientos de inventario detallados
CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id SERIAL PRIMARY KEY,
    id_producto INTEGER REFERENCES productos(id) ON DELETE CASCADE,
    tipo_movimiento VARCHAR(20) NOT NULL, -- 'entrada', 'salida', 'ajuste'
    cantidad INTEGER NOT NULL,
    stock_anterior INTEGER NOT NULL,
    stock_nuevo INTEGER NOT NULL,
    motivo VARCHAR(255),
    referencia_venta INTEGER REFERENCES Ventas(id),
    referencia_compra INTEGER REFERENCES Compras(id),
    usuario_responsable INTEGER REFERENCES usuarios(id),
    fecha_movimiento TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Tabla para alertas de inventario
CREATE TABLE IF NOT EXISTS alertas_inventario (
    id SERIAL PRIMARY KEY,
    id_producto INTEGER REFERENCES productos(id) ON DELETE CASCADE,
    tipo_alerta VARCHAR(30) NOT NULL, -- 'stock_bajo', 'sin_stock', 'vencimiento'
    mensaje TEXT,
    stock_actual INTEGER,
    stock_minimo INTEGER,
    fecha_alerta TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_resolucion TIMESTAMP WITH TIME ZONE,
    estado VARCHAR(20) DEFAULT 'pendiente' -- 'pendiente', 'resuelto', 'ignorado'
);

-- 6. Tabla para métricas de rendimiento por período
CREATE TABLE IF NOT EXISTS metricas_periodo (
    id SERIAL PRIMARY KEY,
    periodo VARCHAR(20) NOT NULL, -- 'diario', 'semanal', 'mensual', 'anual'
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    total_ventas INTEGER DEFAULT 0,
    total_compras INTEGER DEFAULT 0,
    ingresos_totales DECIMAL(12,2) DEFAULT 0.00,
    costos_totales DECIMAL(12,2) DEFAULT 0.00,
    utilidad_bruta DECIMAL(12,2) DEFAULT 0.00,
    margen_utilidad DECIMAL(5,2) DEFAULT 0.00,
    productos_activos INTEGER DEFAULT 0,
    productos_vendidos INTEGER DEFAULT 0,
    rotacion_inventario DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(periodo, fecha_inicio, fecha_fin)
);

-- 7. Tabla para top productos por categoría
CREATE TABLE IF NOT EXISTS top_productos_categoria (
    id SERIAL PRIMARY KEY,
    id_categoria INTEGER REFERENCES categorias_productos(id) ON DELETE CASCADE,
    id_producto INTEGER REFERENCES productos(id) ON DELETE CASCADE,
    periodo VARCHAR(20) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    cantidad_vendida INTEGER DEFAULT 0,
    ingresos DECIMAL(10,2) DEFAULT 0.00,
    posicion INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(id_categoria, id_producto, periodo, fecha_inicio)
);

-- 8. Tabla para análisis de clientes/vendedores
CREATE TABLE IF NOT EXISTS analisis_vendedores (
    id SERIAL PRIMARY KEY,
    id_usuario INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    periodo VARCHAR(20) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    ventas_realizadas INTEGER DEFAULT 0,
    monto_vendido DECIMAL(12,2) DEFAULT 0.00,
    productos_vendidos INTEGER DEFAULT 0,
    promedio_venta DECIMAL(10,2) DEFAULT 0.00,
    mejor_dia DATE,
    mejor_venta DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(id_usuario, periodo, fecha_inicio)
);

-- 9. Tabla para comparativas períodos
CREATE TABLE IF NOT EXISTS comparativas_periodo (
    id SERIAL PRIMARY KEY,
    tipo_comparacion VARCHAR(30) NOT NULL, -- 'mes_anterior', 'año_anterior', 'mismo_mes_año_anterior'
    periodo_actual_inicio DATE NOT NULL,
    periodo_actual_fin DATE NOT NULL,
    periodo_comparacion_inicio DATE NOT NULL,
    periodo_comparacion_fin DATE NOT NULL,
    ventas_actual INTEGER DEFAULT 0,
    ventas_comparacion INTEGER DEFAULT 0,
    crecimiento_ventas DECIMAL(5,2) DEFAULT 0.00,
    ingresos_actual DECIMAL(12,2) DEFAULT 0.00,
    ingresos_comparacion DECIMAL(12,2) DEFAULT 0.00,
    crecimiento_ingresos DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Tabla para reportes personalizados guardados
CREATE TABLE IF NOT EXISTS reportes_guardados (
    id SERIAL PRIMARY KEY,
    nombre_reporte VARCHAR(100) NOT NULL,
    descripcion TEXT,
    tipo_reporte VARCHAR(50) NOT NULL,
    parametros JSONB, -- Parámetros del reporte en formato JSON
    created_by INTEGER REFERENCES usuarios(id),
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ================================================================

-- Índices para resumen_ventas_diario
CREATE INDEX IF NOT EXISTS idx_resumen_ventas_fecha ON resumen_ventas_diario(fecha);
CREATE INDEX IF NOT EXISTS idx_resumen_ventas_mes ON resumen_ventas_diario(EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha));

-- Índices para ranking_productos
CREATE INDEX IF NOT EXISTS idx_ranking_productos_periodo ON ranking_productos(periodo, fecha_inicio, fecha_fin);
CREATE INDEX IF NOT EXISTS idx_ranking_productos_posicion ON ranking_productos(periodo, posicion);

-- Índices para movimientos_inventario
CREATE INDEX IF NOT EXISTS idx_movimientos_producto ON movimientos_inventario(id_producto);
CREATE INDEX IF NOT EXISTS idx_movimientos_fecha ON movimientos_inventario(fecha_movimiento);
CREATE INDEX IF NOT EXISTS idx_movimientos_tipo ON movimientos_inventario(tipo_movimiento);

-- Índices para alertas_inventario
CREATE INDEX IF NOT EXISTS idx_alertas_estado ON alertas_inventario(estado);
CREATE INDEX IF NOT EXISTS idx_alertas_producto ON alertas_inventario(id_producto);
CREATE INDEX IF NOT EXISTS idx_alertas_fecha ON alertas_inventario(fecha_alerta);

-- Índices para métricas_periodo
CREATE INDEX IF NOT EXISTS idx_metricas_periodo_tipo ON metricas_periodo(periodo);
CREATE INDEX IF NOT EXISTS idx_metricas_fechas ON metricas_periodo(fecha_inicio, fecha_fin);

-- ================================================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA
-- ================================================================

-- Trigger para actualizar resumen_ventas_diario cuando se inserta una venta
CREATE OR REPLACE FUNCTION actualizar_resumen_ventas_diario()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO resumen_ventas_diario (
        fecha, total_ventas, ingreso_total,
        ventas_efectivo, ventas_tarjeta, ventas_transferencia,
        monto_efectivo, monto_tarjeta, monto_transferencia
    )
    VALUES (
        DATE(NEW.fecha), 1, NEW.total,
        CASE WHEN NEW.metodo_pago = 'efectivo' THEN 1 ELSE 0 END,
        CASE WHEN NEW.metodo_pago = 'tarjeta' THEN 1 ELSE 0 END,
        CASE WHEN NEW.metodo_pago = 'transferencia' THEN 1 ELSE 0 END,
        CASE WHEN NEW.metodo_pago = 'efectivo' THEN NEW.total ELSE 0 END,
        CASE WHEN NEW.metodo_pago = 'tarjeta' THEN NEW.total ELSE 0 END,
        CASE WHEN NEW.metodo_pago = 'transferencia' THEN NEW.total ELSE 0 END
    )
    ON CONFLICT (fecha) DO UPDATE SET
        total_ventas = resumen_ventas_diario.total_ventas + 1,
        ingreso_total = resumen_ventas_diario.ingreso_total + NEW.total,
        ventas_efectivo = resumen_ventas_diario.ventas_efectivo + 
            (CASE WHEN NEW.metodo_pago = 'efectivo' THEN 1 ELSE 0 END),
        ventas_tarjeta = resumen_ventas_diario.ventas_tarjeta + 
            (CASE WHEN NEW.metodo_pago = 'tarjeta' THEN 1 ELSE 0 END),
        ventas_transferencia = resumen_ventas_diario.ventas_transferencia + 
            (CASE WHEN NEW.metodo_pago = 'transferencia' THEN 1 ELSE 0 END),
        monto_efectivo = resumen_ventas_diario.monto_efectivo + 
            (CASE WHEN NEW.metodo_pago = 'efectivo' THEN NEW.total ELSE 0 END),
        monto_tarjeta = resumen_ventas_diario.monto_tarjeta + 
            (CASE WHEN NEW.metodo_pago = 'tarjeta' THEN NEW.total ELSE 0 END),
        monto_transferencia = resumen_ventas_diario.monto_transferencia + 
            (CASE WHEN NEW.metodo_pago = 'transferencia' THEN NEW.total ELSE 0 END),
        promedio_venta = (resumen_ventas_diario.ingreso_total + NEW.total) / 
            (resumen_ventas_diario.total_ventas + 1),
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_resumen_ventas
    AFTER INSERT ON Ventas
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_resumen_ventas_diario();

-- Trigger para registrar movimientos de inventario en cambios de stock
CREATE OR REPLACE FUNCTION registrar_movimiento_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.stock != NEW.stock THEN
        INSERT INTO movimientos_inventario (
            id_producto, tipo_movimiento, cantidad,
            stock_anterior, stock_nuevo, motivo
        )
        VALUES (
            NEW.id,
            CASE 
                WHEN NEW.stock > OLD.stock THEN 'entrada'
                WHEN NEW.stock < OLD.stock THEN 'salida'
                ELSE 'ajuste'
            END,
            ABS(NEW.stock - OLD.stock),
            OLD.stock,
            NEW.stock,
            'Actualización automática de stock'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_movimiento_stock
    AFTER UPDATE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION registrar_movimiento_stock();

-- Trigger para alertas de stock bajo
CREATE OR REPLACE FUNCTION verificar_stock_bajo()
RETURNS TRIGGER AS $$
BEGIN
    -- Alerta de stock bajo (menos de 10 unidades)
    IF NEW.stock < 10 AND NEW.stock > 0 THEN
        INSERT INTO alertas_inventario (
            id_producto, tipo_alerta, mensaje, stock_actual, stock_minimo
        )
        VALUES (
            NEW.id, 'stock_bajo',
            'Stock bajo: ' || NEW.nombre || ' tiene solo ' || NEW.stock || ' unidades',
            NEW.stock, 10
        )
        ON CONFLICT (id_producto, tipo_alerta) 
        WHERE fecha_resolucion IS NULL
        DO UPDATE SET
            mensaje = EXCLUDED.mensaje,
            stock_actual = EXCLUDED.stock_actual,
            fecha_alerta = NOW();
    END IF;
    
    -- Alerta de sin stock
    IF NEW.stock = 0 THEN
        INSERT INTO alertas_inventario (
            id_producto, tipo_alerta, mensaje, stock_actual, stock_minimo
        )
        VALUES (
            NEW.id, 'sin_stock',
            'Sin stock: ' || NEW.nombre || ' agotado',
            NEW.stock, 1
        )
        ON CONFLICT (id_producto, tipo_alerta) 
        WHERE fecha_resolucion IS NULL
        DO UPDATE SET
            mensaje = EXCLUDED.mensaje,
            stock_actual = EXCLUDED.stock_actual,
            fecha_alerta = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_alertas_stock
    AFTER UPDATE ON productos
    FOR EACH ROW
    EXECUTE FUNCTION verificar_stock_bajo();

-- ================================================================
-- FUNCIONES AUXILIARES PARA REPORTES
-- ================================================================

-- Función para calcular métricas del período
CREATE OR REPLACE FUNCTION calcular_metricas_periodo(
    p_fecha_inicio DATE,
    p_fecha_fin DATE,
    p_tipo_periodo VARCHAR(20)
)
RETURNS VOID AS $$
DECLARE
    v_total_ventas INTEGER;
    v_total_compras INTEGER;
    v_ingresos DECIMAL(12,2);
    v_costos DECIMAL(12,2);
    v_utilidad DECIMAL(12,2);
    v_margen DECIMAL(5,2);
    v_productos_activos INTEGER;
    v_productos_vendidos INTEGER;
BEGIN
    -- Calcular ventas
    SELECT COUNT(*), COALESCE(SUM(total), 0)
    INTO v_total_ventas, v_ingresos
    FROM Ventas
    WHERE fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
    
    -- Calcular compras
    SELECT COUNT(*), COALESCE(SUM(total), 0)
    INTO v_total_compras, v_costos
    FROM Compras
    WHERE fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
    
    -- Calcular utilidad y margen
    v_utilidad := v_ingresos - v_costos;
    v_margen := CASE WHEN v_ingresos > 0 THEN (v_utilidad / v_ingresos) * 100 ELSE 0 END;
    
    -- Productos activos
    SELECT COUNT(*) INTO v_productos_activos FROM productos WHERE stock > 0;
    
    -- Productos vendidos (únicos)
    SELECT COUNT(DISTINCT unnest(id_productos))
    INTO v_productos_vendidos
    FROM Ventas
    WHERE fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
    
    -- Insertar o actualizar métricas
    INSERT INTO metricas_periodo (
        periodo, fecha_inicio, fecha_fin, total_ventas, total_compras,
        ingresos_totales, costos_totales, utilidad_bruta, margen_utilidad,
        productos_activos, productos_vendidos
    )
    VALUES (
        p_tipo_periodo, p_fecha_inicio, p_fecha_fin, v_total_ventas, v_total_compras,
        v_ingresos, v_costos, v_utilidad, v_margen,
        v_productos_activos, v_productos_vendidos
    )
    ON CONFLICT (periodo, fecha_inicio, fecha_fin) DO UPDATE SET
        total_ventas = EXCLUDED.total_ventas,
        total_compras = EXCLUDED.total_compras,
        ingresos_totales = EXCLUDED.ingresos_totales,
        costos_totales = EXCLUDED.costos_totales,
        utilidad_bruta = EXCLUDED.utilidad_bruta,
        margen_utilidad = EXCLUDED.margen_utilidad,
        productos_activos = EXCLUDED.productos_activos,
        productos_vendidos = EXCLUDED.productos_vendidos;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- VISTAS PARA CONSULTAS RÁPIDAS
-- ================================================================

-- Vista para dashboard principal
CREATE OR REPLACE VIEW vista_dashboard AS
SELECT 
    (SELECT COUNT(*) FROM Ventas WHERE DATE(fecha) = CURRENT_DATE) as ventas_hoy,
    (SELECT COALESCE(SUM(total), 0) FROM Ventas WHERE DATE(fecha) = CURRENT_DATE) as ingresos_hoy,
    (SELECT COUNT(*) FROM productos WHERE stock < 10) as productos_stock_bajo,
    (SELECT COUNT(*) FROM productos WHERE stock = 0) as productos_sin_stock,
    (SELECT COUNT(*) FROM alertas_inventario WHERE estado = 'pendiente') as alertas_pendientes,
    (SELECT COUNT(*) FROM productos) as total_productos,
    (SELECT COUNT(*) FROM Ventas WHERE DATE(fecha) = CURRENT_DATE - INTERVAL '1 day') as ventas_ayer,
    (SELECT COALESCE(SUM(total), 0) FROM Ventas WHERE DATE(fecha) = CURRENT_DATE - INTERVAL '1 day') as ingresos_ayer;

-- Vista para productos más vendidos del mes
CREATE OR REPLACE VIEW vista_productos_mes AS
SELECT 
    p.id,
    p.nombre,
    p.precio,
    p.stock,
    COUNT(v.id) as veces_vendido,
    SUM(v.total) as ingresos_generados
FROM productos p
LEFT JOIN Ventas v ON p.id = ANY(v.id_productos)
WHERE v.fecha >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY p.id, p.nombre, p.precio, p.stock
ORDER BY veces_vendido DESC, ingresos_generados DESC
LIMIT 20;

-- Vista para resumen mensual
CREATE OR REPLACE VIEW vista_resumen_mensual AS
SELECT 
    DATE_TRUNC('month', fecha) as mes,
    COUNT(*) as total_ventas,
    SUM(total) as ingresos_totales,
    AVG(total) as promedio_venta,
    MIN(total) as venta_minima,
    MAX(total) as venta_maxima
FROM Ventas
WHERE fecha >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', fecha)
ORDER BY mes DESC;

-- ================================================================
-- COMENTARIOS Y DOCUMENTATION
-- ================================================================

COMMENT ON TABLE resumen_ventas_diario IS 'Tabla optimizada para reportes diarios de ventas';
COMMENT ON TABLE ranking_productos IS 'Tracking de productos más vendidos por período';
COMMENT ON TABLE historico_precios IS 'Historial de cambios de precios de productos';
COMMENT ON TABLE movimientos_inventario IS 'Registro detallado de todos los movimientos de stock';
COMMENT ON TABLE alertas_inventario IS 'Sistema de alertas para gestión de inventario';
COMMENT ON TABLE metricas_periodo IS 'Métricas precalculadas por período para reportes rápidos';
COMMENT ON TABLE top_productos_categoria IS 'Top productos por categoría en períodos específicos';
COMMENT ON TABLE analisis_vendedores IS 'Análisis de rendimiento por vendedor/usuario';
COMMENT ON TABLE comparativas_periodo IS 'Comparaciones entre períodos para análisis de crecimiento';
COMMENT ON TABLE reportes_guardados IS 'Reportes personalizados guardados por usuarios';

-- ================================================================
-- DATOS INICIALES Y CONFIGURACIÓN
-- ================================================================

-- Insertar algunos reportes predefinidos
INSERT INTO reportes_guardados (nombre_reporte, descripcion, tipo_reporte, parametros, is_public) VALUES
('Ventas Diarias', 'Reporte de ventas del día actual', 'ventas_diarias', '{"periodo": "hoy"}', true),
('Top 10 Productos', 'Los 10 productos más vendidos del mes', 'productos_top', '{"limite": 10, "periodo": "mes"}', true),
('Resumen Mensual', 'Resumen completo de ventas del mes', 'resumen_mensual', '{"periodo": "mes_actual"}', true),
('Alertas Inventario', 'Productos con stock bajo o agotado', 'alertas_stock', '{"incluir_resueltas": false}', true),
('Análisis Financiero', 'Resumen de ingresos vs gastos', 'financiero', '{"periodo": "mes_actual"}', true);
