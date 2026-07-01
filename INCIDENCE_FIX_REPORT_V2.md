# Informe de Corrección de Incidencias v2 - Toklen

Este informe documenta las correcciones aplicadas para estabilizar los flujos de perfil, categorías, verificaciones y servicios en Toklen.

## 1. Edición de Perfil y Foto (Incidencia 1)
- **Causa Raíz:** La subida inmediata de la imagen invalidaba el estado global de autenticación, forzando una reconstrucción de la pantalla que descartaba los cambios locales en los controladores de texto.
- **Solución:** Se implementó un estado local para la vista previa de la imagen. La subida real se pospone hasta que el usuario confirma todos los cambios pulsando "Guardar cambios", asegurando una experiencia de edición atómica y sin interrupciones.
- **Archivos Modificados:** `lib/features/profile/presentation/screens/profile_screen.dart`

## 2. Validación de Dirección (Incidencia 2)
- **Causa Raíz:** Falta de reglas de validación en el campo de entrada.
- **Solución:** Se añadió un validador que requiere al menos 5 caracteres y prohíbe entradas compuestas exclusivamente por números o símbolos, mejorando la integridad de los perfiles.
- **Archivos Modificados:** `lib/features/profile/presentation/screens/profile_screen.dart`

## 3. Persistencia de Imagen en Categorías (Incidencia 3)
- **Causa Raíz:** Desajuste entre el nombre del campo en el frontend (`image`) y el backend (`image_url`).
- **Solución:** Se estandarizó el uso de `image_url` en todas las capas del frontend (Admin Screen, Repository y Widget).
- **Archivos Modificados:**
    - `lib/features/admin/presentation/screens/admin_categories_screen.dart`
    - `lib/features/admin/presentation/widgets/category_card.dart`

## 4. Notificaciones de Verificación (Incidencia 4)
- **Causa Raíz:** El proceso de verificación era silencioso para el proveedor.
- **Solución:** Se modificó el backend para insertar automáticamente registros en la tabla de notificaciones cuando un administrador aprueba o rechaza una verificación, permitiendo que el proveedor reciba feedback inmediato en su bandeja de entrada.
- **Archivos Modificados:** `professional-services-api/app/api/v1/endpoints/admin.py`

## 5. Refresco de Categorías en Tiempo Real (Incidencia 5)
- **Causa Raíz:** La invalidación de caché era parcial, afectando solo a la vista de administrador.
- **Solución:** Se añadió la invalidación del provider de categorías de usuario (`user_cat.categoryListProvider`) al crear o editar categorías desde el panel administrativo, garantizando que el nuevo catálogo sea visible instantáneamente para todos los roles.
- **Archivos Modificados:** `lib/features/admin/presentation/screens/admin_categories_screen.dart`

## 6. Estado de Activación de Servicios (Incidencia 6)
- **Causa Raíz:** Desconexión lógica en el switch de la lista de servicios.
- **Solución:** Se vinculó el switch directamente al controlador de actualización asíncrona, proporcionando retroalimentación mediante un SnackBar y asegurando la persistencia del estado "ACTIVO/INACTIVO".
- **Archivos Modificados:** `lib/features/services/presentation/screens/my_services_screen.dart`

---
**Resultado:** Se han corregido las 6 incidencias críticas. El análisis estático de Flutter no reporta errores (0 issues). La aplicación se siente ahora más fluida, coherente y profesional.
