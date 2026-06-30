from datetime import datetime, timedelta
from sqlalchemy import select, func, case
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User, UserRole
from app.models.service import Service
from app.models.booking import Booking, BookingStatus
from app.models.review import Review
from app.schemas.analytics import (
    AdminDashboardResponse, 
    DashboardSummary, 
    TopService, 
    TopProvider
)

class AnalyticsService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_admin_dashboard(self) -> AdminDashboardResponse:
        # 1. Ingresos Totales (Bookings 'completed')
        revenue_query = select(func.sum(Service.price)).join(Booking).where(
            Booking.status == BookingStatus.COMPLETED
        )
        revenue_result = await self.db.execute(revenue_query)
        ingresos_totales = revenue_result.scalar() or 0.0

        # 2. Tasa de Conversión
        total_bookings_query = select(func.count(Booking.id))
        completed_bookings_query = select(func.count(Booking.id)).where(
            Booking.status == BookingStatus.COMPLETED
        )
        
        total_bookings = (await self.db.execute(total_bookings_query)).scalar() or 0
        completed_bookings = (await self.db.execute(completed_bookings_query)).scalar() or 0
        
        tasa_conversion = (completed_bookings / total_bookings * 100) if total_bookings > 0 else 0.0

        # 3. Crecimiento: Usuarios registrados en los últimos 7 días
        seven_days_ago = datetime.now() - timedelta(days=7)
        new_users_query = select(func.count(User.id)).where(
            User.fecha_creacion >= seven_days_ago
        )
        usuarios_nuevos_7d = (await self.db.execute(new_users_query)).scalar() or 0

        # 4. Total usuarios y proveedores
        total_usuarios = (await self.db.execute(select(func.count(User.id)))).scalar() or 0
        total_proveedores = (await self.db.execute(
            select(func.count(User.id)).where(User.rol == UserRole.PROVIDER)
        )).scalar() or 0
        proveedores_verificados = (await self.db.execute(
            select(func.count(User.id)).where(User.rol == UserRole.PROVIDER, User.is_verified == True)
        )).scalar() or 0
        usuarios_suspendidos = (await self.db.execute(
            select(func.count(User.id)).where(User.is_suspended == True)
        )).scalar() or 0

        total_services = (await self.db.execute(select(func.count(Service.id)))).scalar() or 0

        # 5. Top 5 Servicios: Promedio rating > 0, más de 3 reseñas
        top_services_query = (
            select(
                Service.id,
                Service.title,
                func.avg(Review.rating).label("avg_rating"),
                func.count(Review.id).label("review_count"),
                User.nombre.label("provider_name")
            )
            .join(Booking, Service.id == Booking.service_id)
            .join(Review, Booking.id == Review.booking_id)
            .join(User, Service.provider_id == User.id)
            .group_by(Service.id, User.nombre)
            .having(func.count(Review.id) > 3)
            .order_by(func.avg(Review.rating).desc())
            .limit(5)
        )
        top_services_result = await self.db.execute(top_services_query)
        top_services = [
            TopService(
                service_id=row.id,
                title=row.title,
                average_rating=float(row.avg_rating),
                total_reviews=row.review_count,
                provider_name=row.provider_name
            )
            for row in top_services_result.all()
        ]

        return AdminDashboardResponse(
            summary=DashboardSummary(
                ingresos_totales=float(ingresos_totales),
                tasa_conversion=float(tasa_conversion),
                usuarios_nuevos_7d=usuarios_nuevos_7d,
                total_usuarios=total_usuarios,
                total_proveedores=total_proveedores,
                total_servicios=total_services,
                total_bookings=total_bookings,
                proveedores_verificados=proveedores_verificados,
                usuarios_suspendidos=usuarios_suspendidos,
            ),
            top_services=top_services
        )

    async def get_top_providers(self) -> list[TopProvider]:
        # Lista detallada de proveedores con mejor rendimiento
        query = (
            select(
                User.id,
                User.nombre,
                User.email,
                func.count(func.distinct(Service.id)).label("total_services"),
                func.count(func.distinct(case((Booking.status == BookingStatus.COMPLETED, Booking.id)))).label("completed_bookings"),
                func.sum(case((Booking.status == BookingStatus.COMPLETED, Service.price), else_=0)).label("revenue"),
                func.avg(Review.rating).label("avg_rating")
            )
            .join(Service, User.id == Service.provider_id)
            .outerjoin(Booking, Service.id == Booking.service_id)
            .outerjoin(Review, Booking.id == Review.booking_id)
            .where(User.rol == UserRole.PROVIDER)
            .group_by(User.id)
            .order_by(func.sum(case((Booking.status == BookingStatus.COMPLETED, Service.price), else_=0)).desc())
        )
        
        result = await self.db.execute(query)
        return [
            TopProvider(
                provider_id=row.id,
                nombre=row.nombre,
                email=row.email,
                total_services=row.total_services,
                total_bookings_completed=row.completed_bookings,
                total_revenue=float(row.revenue or 0),
                average_rating=float(row.avg_rating) if row.avg_rating else None
            )
            for row in result.all()
        ]
