# 🗺️ MAPEO COMPLETO - API BACKEND vs FRONTEND

## 📅 Fecha: Enero 16, 2025
## 🎯 Objetivo: Identificar qué endpoints están conectados y qué falta implementar

---

## ✅ MÓDULOS IMPLEMENTADOS Y FUNCIONANDO

### 1. **Auth** (Autenticación)

| Endpoint Backend | Método | Estado Frontend | Archivo |
|-----------------|--------|-----------------|---------|
| `/api/v1/auth/register` | POST | ✅ IMPLEMENTADO | `auth_repository.dart` |
| `/api/v1/auth/login` | POST | ✅ IMPLEMENTADO | `auth_repository.dart` |
| `/api/v1/auth/me` | GET | ✅ IMPLEMENTADO | `auth_repository.dart` |

**Detalles**:
- ✅ Registro con `nombre`, `email`, `password`, `rol`
- ✅ Login con OAuth2 (username + password, form-urlencoded)
- ✅ Validación de sesión con JWT Bearer Token
- ✅ Manejo de errores 401, 409, 422

---

### 2. **Users** (Perfil de Usuario)

| Endpoint Backend | Método | Estado Frontend | Archivo |
|-----------------|--------|-----------------|---------|
| `/api/v1/users/me` | GET | ✅ IMPLEMENTADO | `profile_repository.dart` |
| `/api/v1/users/me` | PUT | ✅ IMPLEMENTADO | `profile_repository.dart` |
| `/api/v1/users/me/profile-picture` | POST | ✅ IMPLEMENTADO | `profile_repository.dart` |

**Detalles**:
- ✅ Ver perfil completo
- ✅ Editar `nombre`, `phone`, `bio`, `address`
- ✅ Subir foto de perfil (multipart/form-data con MediaType correcto)
- ✅ Pantalla responsive con LayoutBuilder
- ✅ Badge de rol (Cliente/Proveedor)

---

### 3. **Services** (Servicios)

| Endpoint Backend | Método | Estado Frontend | Archivo |
|-----------------|--------|-----------------|---------|
| `/api/v1/services/` | POST | ✅ IMPLEMENTADO | `service_repository.dart` |
| `/api/v1/services/` | GET | ✅ IMPLEMENTADO | `service_repository.dart` |
| `/api/v1/services/{service_id}` | GET | ✅ IMPLEMENTADO | `service_repository.dart` |
| `/api/v1/services/{service_id}` | PUT | ✅ IMPLEMENTADO | `service_repository.dart` |
| `/api/v1/services/{service_id}` | DELETE | ✅ IMPLEMENTADO | `service_repository.dart` |
| `/api/v1/services/{service_id}/gallery` | POST | ✅ IMPLEMENTADO | `service_repository.dart` |
| `/api/v1/services/{service_id}/gallery/{image_id}` | DELETE | ✅ IMPLEMENTADO | `service_repository.dart` |

**Detalles**:
- ✅ CRUD completo de servicios
- ✅ Filtrar por `category_id`
- ✅ Galería de imágenes (subir y eliminar)
- ✅ Pantallas: List, Detail, Add, Manage, MyServices

---

### 4. **Categories** (Categorías)

| Endpoint Backend | Método | Estado Frontend | Archivo |
|-----------------|--------|-----------------|---------|
| `/api/v1/categories/` | GET | ✅ IMPLEMENTADO | `category_repository.dart` |
| `/api/v1/categories/` | POST | ⚠️ SOLO ADMIN | - |

**Detalles**:
- ✅ Listar todas las categorías
- ✅ Grid view con iconos dinámicos
- ⚠️ Crear categoría es endpoint de admin (no implementado en frontend)

---

## ⏳ MÓDULOS PENDIENTES DE IMPLEMENTAR

### 5. **Bookings** (Reservas) - **ALTA PRIORIDAD**

| Endpoint Backend | Método | Estado Frontend | Acción Requerida |
|-----------------|--------|-----------------|------------------|
| `/api/v1/bookings/` | POST | ❌ NO IMPLEMENTADO | Crear pantalla de crear reserva |
| `/api/v1/bookings/my-bookings` | GET | ❌ NO IMPLEMENTADO | Pantalla "Mis Reservas" (cliente) |
| `/api/v1/bookings/requests` | GET | ❌ NO IMPLEMENTADO | Pantalla "Solicitudes" (proveedor) |
| `/api/v1/bookings/{booking_id}/status` | PATCH | ❌ NO IMPLEMENTADO | Actualizar estado de reserva |

**Arquitectura Necesaria**:
```
features/bookings/
├── data/
│   ├── models/
│   │   ├── booking_model.dart
│   │   ├── booking_create.dart
│   │   └── booking_status.dart
│   └── repositories/
│       └── booking_repository.dart
└── presentation/
    ├── providers/
    │   ├── booking_state.dart
    │   └── booking_provider.dart
    └── screens/
        ├── create_booking_screen.dart
        ├── my_bookings_screen.dart
        └── booking_requests_screen.dart
```

**Flujo de Usuario**:
1. Cliente ve servicio → Click en "Reservar"
2. Selecciona fecha/hora del horario del proveedor
3. Escribe mensaje/requisitos
4. Envía solicitud de reserva
5. Proveedor recibe notificación
6. Proveedor acepta/rechaza reserva
7. Cliente ve estado actualizado

---

### 6. **Reviews** (Reseñas) - **ALTA PRIORIDAD**

| Endpoint Backend | Método | Estado Frontend | Acción Requerida |
|-----------------|--------|-----------------|------------------|
| `/api/v1/reviews/` | POST | ❌ NO IMPLEMENTADO | Form para crear reseña |
| `/api/v1/reviews/service/{service_id}` | GET | ❌ NO IMPLEMENTADO | Mostrar reseñas en detalle de servicio |

**Integración Necesaria**:
- Agregar lista de reseñas en `ServiceDetailScreen`
- Agregar botón "Dejar reseña" (solo si completó el servicio)
- Widget de estrellas (rating)
- Card de reseña con avatar, nombre, fecha, comentario

**Modelo**:
```dart
class ReviewModel {
  final String id;
  final String clientId;
  final String clientName;
  final String serviceId;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
}
```

---

### 7. **Chat & Notifications** (Chat y Notificaciones) - **MEDIA PRIORIDAD**

| Endpoint Backend | Método | Estado Frontend | Acción Requerida |
|-----------------|--------|-----------------|------------------|
| `/api/v1/chat/send` | POST | ❌ NO IMPLEMENTADO | Pantalla de chat 1:1 |
| `/api/v1/chat/history/{contact_id}` | GET | ❌ NO IMPLEMENTADO | Historial de mensajes |
| `/api/v1/chat/inbox` | GET | ❌ NO IMPLEMENTADO | Lista de conversaciones |
| `/api/v1/chat/notifications` | GET | ❌ NO IMPLEMENTADO | Centro de notificaciones |
| `/api/v1/chat/notifications/{id}/read` | PATCH | ❌ NO IMPLEMENTADO | Marcar como leída |

**Arquitectura Necesaria**:
```
features/chat/
├── data/
│   ├── models/
│   │   ├── message_model.dart
│   │   ├── inbox_item_model.dart
│   │   └── notification_model.dart
│   └── repositories/
│       └── chat_repository.dart
└── presentation/
    ├── providers/
    │   ├── chat_state.dart
    │   └── chat_provider.dart
    └── screens/
        ├── inbox_screen.dart
        ├── chat_screen.dart
        └── notifications_screen.dart
```

**Features Clave**:
- Lista de conversaciones (inbox)
- Chat en tiempo real (polling cada X segundos o WebSocket)
- Badge con contador de mensajes no leídos
- Notificaciones push (opcional)

---

### 8. **Quotes & Negotiation** (Cotizaciones) - **MEDIA PRIORIDAD**

| Endpoint Backend | Método | Estado Frontend | Acción Requerida |
|-----------------|--------|-----------------|------------------|
| `/api/v1/quotes/` | POST | ❌ NO IMPLEMENTADO | Solicitar cotización desde servicio |
| `/api/v1/quotes/{quote_id}/respond` | PATCH | ❌ NO IMPLEMENTADO | Proveedor responde con precio |

**Flujo**:
1. Cliente ve servicio sin precio fijo
2. Click en "Solicitar Cotización"
3. Describe lo que necesita
4. Proveedor recibe solicitud
5. Proveedor responde con precio y descripción
6. Cliente acepta/rechaza
7. Si acepta → se crea Booking automáticamente

---

### 9. **Schedules** (Horarios) - **BAJA PRIORIDAD**

| Endpoint Backend | Método | Estado Frontend | Acción Requerida |
|-----------------|--------|-----------------|------------------|
| `/api/v1/schedules/` | POST | ❌ NO IMPLEMENTADO | Proveedor configura disponibilidad |
| `/api/v1/schedules/{provider_id}` | GET | ❌ NO IMPLEMENTADO | Ver horarios al reservar |

**Uso**:
- Proveedor define: Lunes 9-18h, Martes 10-14h, etc.
- Cliente ve slots disponibles al hacer reserva
- Sistema bloquea horarios ya reservados

---

### 10. **Admin Analytics** (Analíticas Admin) - **MUY BAJA PRIORIDAD**

| Endpoint Backend | Método | Estado Frontend | Acción Requerida |
|-----------------|--------|-----------------|------------------|
| `/api/v1/admin/dashboard/summary` | GET | ❌ NO IMPLEMENTADO | Dashboard de administrador |
| `/api/v1/admin/reports/top-providers` | GET | ❌ NO IMPLEMENTADO | Reportes y estadísticas |
| `/api/v1/admin/users/{user_id}/verify` | POST | ❌ NO IMPLEMENTADO | Verificar proveedores |

**Nota**: Solo para rol `admin`. No es prioridad para MVP.

---

## 📊 RESUMEN DE PRIORIDADES

### 🔴 ALTA PRIORIDAD (CORE DEL MARKETPLACE)
1. ✅ **Auth** - COMPLETADO
2. ✅ **Users** - COMPLETADO
3. ✅ **Services** - COMPLETADO
4. ✅ **Categories** - COMPLETADO
5. ⏳ **Bookings** - PENDIENTE (crítico para funcionalidad)
6. ⏳ **Reviews** - PENDIENTE (crítico para confianza)

### 🟡 MEDIA PRIORIDAD (MEJORAN UX)
7. ⏳ **Chat & Notifications** - PENDIENTE
8. ⏳ **Quotes** - PENDIENTE

### 🟢 BAJA PRIORIDAD (NICE TO HAVE)
9. ⏳ **Schedules** - PENDIENTE
10. ⏳ **Admin Analytics** - PENDIENTE

---

## 🎯 PLAN DE IMPLEMENTACIÓN SUGERIDO

### SPRINT 1: Bookings (Reservas) - **2-3 días**
- [ ] Crear modelos de Booking
- [ ] Crear BookingRepository
- [ ] Crear BookingProvider con AsyncNotifier
- [ ] Pantalla: CreateBookingScreen
- [ ] Pantalla: MyBookingsScreen (cliente)
- [ ] Pantalla: BookingRequestsScreen (proveedor)
- [ ] Integrar botón "Reservar" en ServiceDetailScreen
- [ ] Estados: Pending, Confirmed, Completed, Cancelled

### SPRINT 2: Reviews (Reseñas) - **1-2 días**
- [ ] Crear modelos de Review
- [ ] Crear ReviewRepository
- [ ] Crear ReviewProvider
- [ ] Widget: StarRating (selector de 1-5 estrellas)
- [ ] Widget: ReviewCard
- [ ] Integrar lista de reviews en ServiceDetailScreen
- [ ] Form de crear reseña (solo si completó booking)

### SPRINT 3: Chat & Notifications - **3-4 días**
- [ ] Crear modelos de Chat y Notification
- [ ] Crear ChatRepository
- [ ] Crear ChatProvider
- [ ] Pantalla: InboxScreen (lista de conversaciones)
- [ ] Pantalla: ChatScreen (mensajes 1:1)
- [ ] Pantalla: NotificationsScreen
- [ ] Badge con contador en barra de navegación
- [ ] Polling cada 30 segundos para nuevos mensajes

### SPRINT 4: Quotes & Schedules - **2-3 días**
- [ ] Módulo de Quotes
- [ ] Módulo de Schedules
- [ ] Integración en flujo de reservas

---

## 🚀 COMANDOS PARA COMPILAR Y PROBAR

```bash
cd professional_services_app

# Limpiar caché
flutter clean

# Instalar dependencias
flutter pub get

# Compilar y ejecutar
flutter run -d chrome

# O en modo release (más rápido)
flutter run -d chrome --release
```

---

## 📝 ESTADO ACTUAL DEL PROYECTO

### ✅ COMPLETADO (60% del MVP)
- Sistema de autenticación completo
- Perfil de usuario con foto
- CRUD de servicios con galería
- Navegación con guards
- Responsive en ProfileScreen
- Manejo robusto de errores

### ⏳ PENDIENTE (40% del MVP)
- Módulo de reservas (crítico)
- Módulo de reseñas (crítico)
- Chat y notificaciones
- Cotizaciones
- Horarios

### 🎯 PRÓXIMO PASO INMEDIATO
**Implementar el módulo de Bookings (Reservas)** ya que es el core de la funcionalidad del marketplace. Sin reservas, los usuarios no pueden contratar servicios.

---

**¿Quieres que empiece a implementar el módulo de Bookings ahora?** 🚀
