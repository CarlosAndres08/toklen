# Informe de Corrección de Incidencias - Toklen

Este informe detalla las soluciones aplicadas a las 6 incidencias detectadas durante las pruebas funcionales del sistema.

## 1. Edición del Perfil (Flujo de Imagen)
- **Causa Raíz:** El evento de selección de imagen disparaba una subida inmediata que refrescaba el estado global (invalidando el `authControllerProvider`), lo que provocaba la reconstrucción de la pantalla y la pérdida de los cambios no guardados en los controladores de texto.
- **Solución:** Se modificó `ProfileScreen` para almacenar la imagen seleccionada en un estado local (`_selectedImage`). Ahora se muestra una vista previa inmediata sin subir el archivo. La subida se realiza secuencialmente solo cuando el usuario pulsa "Guardar cambios", garantizando que no se pierda el contexto ni los datos del formulario.
- **Archivos Modificados:** `lib/features/profile/presentation/screens/profile_screen.dart`

## 2. Validación de Dirección
- **Causa Raíz:** El campo carecía de lógica de validación, permitiendo textos cortos o irrelevantes.
- **Solución:** Se implementó un validador en el `AppTextField` de dirección que exige un mínimo de 5 caracteres y rechaza entradas que contengan únicamente números, mejorando la calidad de la información geográfica.
- **Archivos Modificados:** `lib/features/profile/presentation/screens/profile_screen.dart`

## 3. Imagen/Icono de Categorías
- **Causa Raíz:** El frontend enviaba el campo bajo la clave `image`, mientras que el backend de FastAPI esperaba `image_url` según su esquema Pydantic. Además, no se estaba persistiendo la URL después de la subida en el diálogo de edición.
- **Solución:** Se sincronizó el nombre del campo a `image_url` en el repositorio y la pantalla de administración. Se ajustó el `CategoryCard` para que priorice `image_url` al renderizar la imagen.
- **Archivos Modificados:**
    - `lib/features/admin/presentation/screens/admin_categories_screen.dart`
    - `lib/features/admin/presentation/widgets/category_card.dart`

## 4. Verificación de Proveedores
- **Causa Raíz:** La acción de verificar era puramente administrativa en BD sin feedback hacia el usuario final.
- **Solución:**
    - **Backend:** Se integró el `NotificationRepository` en los endpoints de verificación para crear notificaciones persistentes que el proveedor recibe al ser aprobado o rechazado.
    - **Frontend:** Se añadió un banner informativo en `AddServiceScreen` para proveedores no verificados, explicando que sus servicios tienen menor prioridad, incentivando el proceso de validación.
- **Archivos Modificados:**
    - `professional-services-api/app/api/v1/endpoints/admin.py`
    - `lib/features/services/presentation/screens/add_service_screen.dart`

## 5. Refresco de Categorías
- **Causa Raíz:** Al crear una categoría, solo se invalidaba el proveedor de la lista administrativa, dejando el caché del catálogo de usuarios desactualizado.
- **Solución:** Se añadió la invalidación explícita de `user_cat.categoryListProvider` en el flujo de creación y edición de categorías del panel administrativo.
- **Archivos Modificados:** `lib/features/admin/presentation/screens/admin_categories_screen.dart`

## 6. Activar / Desactivar Servicio
- **Causa Raíz:** El switch en la lista de "Mis Publicaciones" no tenía vinculada la llamada al controlador de actualización de servicios.
- **Solución:** Se conectó el `onChanged` del switch con `updateServiceControllerProvider.notifier.executeUpdate`. Ahora el cambio de estado es persistente, funcional para el proveedor y ofrece feedback visual inmediato mediante un SnackBar.
- **Archivos Modificados:** `lib/features/services/presentation/screens/my_services_screen.dart`

## 7. Módulo de Reseñas (Estabilización y CRUD)
- **Causa Raíz:** Las reseñas no aparecían inmediatamente debido a que no se invalidaban los providers de caché tras la creación. Además, el sistema original no permitía editar ni eliminar reseñas una vez publicadas.
- **Solución:**
    - **Backend:** Se implementaron los endpoints PUT y DELETE para reseñas en FastAPI, incluyendo validaciones de autoría para asegurar que solo el creador pueda modificar su opinión.
    - **Frontend:** Se refactorizó `ReviewController` para realizar una invalidación en cascada (`ref.invalidate`) que actualiza inmediatamente la lista de reseñas, el promedio de estrellas en el detalle del servicio y el perfil del proveedor.
    - **UX:** Se añadió un menú de opciones (Editar/Eliminar) en cada `ReviewCard` visible solo para el autor, y se integró el `ReviewForm` para soportar actualizaciones.
- **Archivos Modificados:**
    - `professional-services-api/app/api/v1/endpoints/reviews.py`
    - `professional-services-api/app/services/review_manager.py`
    - `professional-services-api/app/repositories/review_repository.py`
    - `lib/features/reviews/presentation/providers/review_provider.dart`
    - `lib/features/reviews/presentation/widgets/review_card.dart`

---
**Resultado Final:** Se han corregido las incidencias detectadas y se ha estabilizado el módulo de reseñas con capacidades CRUD completas. La aplicación mantiene 0 errores de linter y una sincronización de datos en tiempo real.
