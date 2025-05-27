#!/bin/bash

echo "🔧 Script de Solución para Permisos de Red en macOS"
echo "=================================================="
echo ""

# Función para mostrar comandos sin ejecutarlos automáticamente
show_command() {
    echo "📋 Ejecuta este comando:"
    echo "   $1"
    echo ""
}

echo "1️⃣ Verificar estado del Firewall:"
show_command "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate"

echo "2️⃣ Si el firewall está activo, permitir Flutter:"
show_command "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/flutter"
show_command "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/flutter"

echo "3️⃣ Permitir conexiones salientes para la aplicación:"
show_command "sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"

echo "4️⃣ Alternativamente, ejecutar Flutter con permisos:"
show_command "sudo flutter run -d macos --verbose"

echo ""
echo "🔒 Para configuración manual del Firewall:"
echo "   • Ve a: Configuración del Sistema > Red > Firewall"
echo "   • Opciones > Permitir automáticamente software firmado"
echo "   • O agrega Flutter manualmente a las excepciones"
echo ""

echo "⚠️  Si nada funciona, prueba desactivar temporalmente el firewall:"
echo "   • Configuración del Sistema > Red > Firewall > Desactivar"
echo "   • Ejecuta la app, luego reactiva el firewall"
echo ""

echo "✅ Una vez configurado, usa:"
echo "   flutter run -d macos"
