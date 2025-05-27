# 🔧 Guía de Solución de Problemas - Invmicho

## 🚫 Error: "Operation not permitted" en macOS

### **Descripción del Problema**
Si ves el error `ClientException with SocketException: Connection failed (OS Error: Operation not permitted, errno = 1)`, significa que macOS está bloqueando las conexiones de red de la aplicación.

### **Soluciones Paso a Paso**

#### **1. Verificar Permisos de Firewall**
1. Abre **Configuración del Sistema** (System Preferences)
2. Ve a **Privacidad y Seguridad** → **Firewall**
3. Si el firewall está activado:
   - Haz clic en **Opciones de Firewall**
   - Busca "invmicho" o "Flutter" en la lista
   - Asegúrate de que esté configurado como **"Permitir conexiones entrantes"**

#### **2. Permitir Conexiones de Red**
1. En **Configuración del Sistema** → **Privacidad y Seguridad**
2. Ve a la pestaña **Privacidad**
3. Selecciona **Acceso a la red local** (Network Access)
4. Activa el permiso para la aplicación Flutter/invmicho

#### **3. Verificar Configuración de Red**
1. Asegúrate de tener conexión a internet estable
2. Verifica que no estés usando una VPN que pueda bloquear conexiones
3. Si estás en una red corporativa, consulta con tu administrador de red

#### **4. Solución Temporal - Ejecutar con Permisos**
Si el problema persiste, puedes probar ejecutar la aplicación con permisos adicionales:

```bash
sudo flutter run -d macos
```

⚠️ **Nota**: Solo usar `sudo` como último recurso y en entornos de desarrollo.

### **5. Usar el Diagnóstico Integrado**
La aplicación incluye un sistema de diagnóstico que te ayudará a identificar el problema:

1. Ejecuta la aplicación (incluso si no se conecta)
2. Ve a **Configuraciones** en el menú lateral
3. Haz clic en **"Diagnóstico"** junto al estado de la base de datos
4. Sigue las recomendaciones específicas que aparezcan

### **6. Modo Offline**
Si no puedes resolver el problema de conexión inmediatamente:

- La aplicación automáticamente entra en **modo offline**
- Puedes seguir usando todas las funciones con datos de prueba
- El banner en la parte superior te notificará el estado de conexión
- Usa el botón **"Reintentar"** después de resolver los problemas de permisos

---

## 🐛 Otros Problemas Comunes

### **Overflow de UI**
Si ves elementos cortados o errores de "RenderFlex overflowed":
- Esto ya ha sido corregido en la versión actual
- Si persiste, reporta el problema con detalles específicos

### **Problemas de Rendimiento**
- La aplicación incluye timeouts de 5-10 segundos para evitar colgarse
- Si la respuesta es lenta, verás mensajes informativos

### **Datos de Prueba**
En modo offline, la aplicación usa:
- **Categorías**: Electrónicos, Ropa, Hogar, Alimentación, Deportes
- **Productos**: Laptop, Smartphone, Camiseta, Mesa, Pan, Bicicleta
- **Proveedores**: TechCorp, ModaStyle, CasaBella, AlimentosFresh, DeportesMax

---

## 📞 Soporte

Si ninguna de estas soluciones funciona:
1. Usa el **sistema de diagnóstico integrado** para obtener información detallada
2. Copia el reporte del diagnóstico
3. Incluye los detalles en tu reporte de problema

**La aplicación está diseñada para funcionar completamente en modo offline, así que siempre podrás usar todas las funciones mientras resuelves los problemas de conexión.**
