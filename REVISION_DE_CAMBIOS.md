# 📝 INFORME DE REVISIÓN DE CAMBIOS - TOKLEN

Este documento detalla todas las modificaciones realizadas hasta el momento como parte de la Fase 1 (Saneamiento) y Fase 2 (UI/UX) del plan de refactorización.

---

## 1. Lista de Archivos Modificados / Creados

### Infraestructura y Core
- `pubspec.yaml`: Se agregaron `dio`, `pretty_dio_logger`, `shimmer` y `fl_chart`. Se ajustó la versión del SDK a `^3.11.0`.
- `lib/core/network/dio_client.dart` (Nuevo): Cliente de red centralizado con interceptores.
- `lib/core/theme/app_colors.dart`: Actualización de paleta cromática profesional.
- `lib/core/theme/app_theme.dart`: Redefinición de tipografía, inputs, cards y appbars.
- `lib/core/widgets/primary_button.dart`: Rediseño completo con soporte para gradientes.
- `lib/core/widgets/app_text_field.dart`: Rediseño para mejorar la usabilidad.
- `lib/core/widgets/skeleton_loader.dart` (Nuevo): Utilidad para efectos de carga.
- `lib/core/widgets/empty_state.dart` (Nuevo): Utilidad para estados sin datos.

### Modelos de Datos (Estandarización)
- `lib/features/auth/data/models/user_model.dart`: Cambio de `name` -> `nombre`, `role` -> `rol`, `created_at` -> `fecha_creacion`.
- `lib/features/services/data/models/service_model.dart`: Consistencia de campos con el backend.
- `lib/features/admin/data/models/user_management_models.dart`: Alineación con el esquema de actualización del backend.

### Repositorios Migrados a Dio
- `lib/features/auth/data/repositories/auth_repository.dart`
- `lib/features/services/data/repositories/service_repository.dart`
- `lib/features/categories/data/repositories/category_repository.dart`
- `lib/features/profile/data/repositories/profile_repository.dart`
- `lib/features/reviews/data/repositories/review_repository.dart`
- `lib/features/schedules/data/repositories/schedule_repository.dart`
- `lib/features/admin/data/repositories/admin_repository.dart`
- `lib/features/admin/data/repositories/user_management_repository.dart`
- `lib/features/admin/data/repositories/category_management_repository.dart`
- `lib/features/admin/data/repositories/service_management_repository.dart`
- `lib/features/admin/data/repositories/verification_repository.dart`

### Pantallas y UI
- `lib/features/categories/presentation/screens/categories_screen.dart`: Integración de Skeletons y nuevo diseño de cards.
- `lib/features/services/presentation/screens/service_detail_screen.dart`: Rediseño integral y mejora de galería.
- `lib/features/admin/presentation/screens/admin_overview_screen.dart`: Implementación de gráficos de actividad.
- `lib/features/admin/presentation/screens/admin_providers_screen.dart`: Nuevo flujo de moderación.
- `lib/features/admin/presentation/screens/admin_users_screen.dart`: Implementación de sistema de suspensiones.

---

## 2. Explicación de los Cambios

### Unificación de Red (Dio)
Se eliminó el uso disperso de `http` por **Dio**. Esto permite:
- **Centralización**: El token de autenticación se inyecta automáticamente en todas las peticiones mediante un interceptor.
- **Robustez**: Mejor manejo de timeouts y errores.
- **Debugging**: Logging profesional en consola para ver las peticiones y respuestas en tiempo real.

### Estandarización de Lenguaje (Spanglish Cleanup)
El backend usa campos en español (`nombre`, `rol`). El frontend tenía una mezcla. He estandarizado los modelos para usar los nombres reales del backend como campos principales, manteniendo "getters" de compatibilidad para evitar romper toda la UI de golpe.

### Sistema de Diseño "Pro"
Se abandonó el look de "plantilla básica" por uno más industrial:
- **Indigo & Emerald**: Colores con mejor contraste y accesibilidad.
- **Jerarquía Visual**: Uso de pesos tipográficos y espaciados consistentes (múltiplos de 4/8).

---

## 3. Riesgos Identificados ⚠️
1. **Rompimiento de Módulos No Migrados**: Al reemplazar `httpClientProvider` por `dioProvider`, los módulos que aún usan `http` (Bookings, Chat, Favoritos) tienen errores de compilación que deben resolverse migrándolos.
2. **Cambios en Modelos**: Cualquier parte de la UI que use `.name` en lugar de `.nombre` (en UserModel) podría fallar si no se usa el alias correctamente.
3. **Interceptores**: Si el backend cambia el formato del token, el interceptor podría fallar y bloquear todas las peticiones.

---

## 4. Incompatibilidades con el Backend
- Actualmente, el frontend está **más alineado** con el backend que antes.
- **Riesgo residual**: Verificación del endpoint `/api/v1/auth/login` (OAuth2 usa `username` en lugar de `email` en el form-data, lo cual ya fue corregido en el nuevo repositorio).

---

## 5. Errores Pendientes (Deuda Técnica)
1. **Errores de Análisis (84 detectados)**: Principalmente referencias a `httpClientProvider` en módulos secundarios.
2. **Refresh Token**: Aún no se ha implementado el refresco automático de tokens si expiran.
3. **Manejo de Errores de Red**: Aunque Dio los captura, la UI aún necesita "Error Boundaries" más amigables.

---

## 6. Funcionalidades No Verificadas (Requieren Backend Real)
- **Subida de Archivos**: Los métodos de `uploadProfilePicture` y `uploadServiceImage` han sido refactorizados pero no probados contra el servidor.
- **WebSockets (Chat)**: No se ha tocado la lógica de chat, por lo que su compatibilidad con el nuevo sistema de red no está garantizada.

---

## 7. Plan de Pruebas Manuales Recomendado
1. **Login/Registro**: Verificar que el flujo de tokens funcione (el interceptor debe guardar y usar el token).
2. **Perfil**: Editar nombre y bio para asegurar que el mapeo `nombre` funcione.
3. **Admin**: Abrir el dashboard y verificar que el gráfico no rompa la pantalla.
4. **Moderación**: Intentar suspender un usuario de prueba.
