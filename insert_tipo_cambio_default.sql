-- Insertar valor por defecto en la tabla tipo_cambio
-- Si ya existe el registro con id=1, se actualiza, si no existe se inserta

INSERT INTO public.tipo_cambio (id, cambio) 
VALUES (1, 17.5)
ON CONFLICT (id) 
DO UPDATE SET cambio = EXCLUDED.cambio;

-- Verificar que se insertó correctamente
SELECT * FROM public.tipo_cambio WHERE id = 1;
