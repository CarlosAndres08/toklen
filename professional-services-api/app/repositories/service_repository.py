import uuid
import math
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.service import Service
from app.models.review import Review
from app.models.booking import Booking


def _haversine(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlng / 2) ** 2
    )
    return round(R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


class ServiceRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def _attach_ratings(self, services: list[Service]) -> None:
        """Asigna average_rating y reviews_count como atributos dinámicos."""
        if not services:
            return
        ids = [s.id for s in services]
        stmt = select(
            Booking.service_id,
            func.avg(Review.rating).label("avg_r"),
            func.count(Review.id).label("cnt"),
        ).join(Review, Review.booking_id == Booking.id).where(
            Booking.service_id.in_(ids)
        ).group_by(Booking.service_id)
        result = await self.db.execute(stmt)
        rating_map: dict[uuid.UUID, tuple[float, int]] = {}
        for row in result:
            rating_map[row.service_id] = (float(row.avg_r), int(row.cnt))
        for s in services:
            data = rating_map.get(s.id)
            if data:
                s.average_rating = round(data[0], 1)
                s.reviews_count = data[1]
            else:
                s.average_rating = None
                s.reviews_count = 0

    async def get_all(
        self,
        only_active: bool = False,
        category_id: uuid.UUID | None = None,
        min_price: float | None = None,
        max_price: float | None = None,
        min_rating: float | None = None,
        q: str | None = None,
        lat: float | None = None,
        lng: float | None = None,
        radius: float | None = None,
        sort_by: str | None = None,
        featured: bool | None = None,
        page: int = 1,
        page_size: int = 20,
    ) -> list[Service]:
        query = select(Service).options(
            selectinload(Service.images),
            selectinload(Service.category),
            selectinload(Service.provider)
        )

        if only_active:
            query = query.where(Service.is_active == True)

        if featured is not None:
            query = query.where(Service.is_featured == featured)

        if category_id:
            query = query.where(Service.category_id == category_id)

        if min_price is not None:
            query = query.where(Service.price >= min_price)

        if max_price is not None:
            query = query.where(Service.price <= max_price)

        if q:
            search_term = f"%{q}%"
            query = query.where(
                (Service.title.ilike(search_term)) | (Service.description.ilike(search_term))
            )

        if min_rating is not None:
            avg_rating_subquery = (
                select(Booking.service_id, func.avg(Review.rating).label("avg_rating"))
                .join(Review, Review.booking_id == Booking.id)
                .group_by(Booking.service_id)
                .subquery()
            )
            query = query.join(
                avg_rating_subquery, Service.id == avg_rating_subquery.c.service_id
            ).where(avg_rating_subquery.c.avg_rating >= min_rating)

        # Filtro por cercanía — bounding box aproximado para reducir datos en DB
        if lat is not None and lng is not None and radius is not None:
            # ~1° de latitud ~111km, ~1° de longitud ~111*cos(lat) km
            lat_delta = radius / 111.0
            lng_delta = radius / (111.0 * math.cos(math.radians(lat)))
            query = query.where(
                Service.latitude.isnot(None),
                Service.longitude.isnot(None),
                Service.latitude.between(lat - lat_delta, lat + lat_delta),
                Service.longitude.between(lng - lng_delta, lng + lng_delta),
            )

        # Ordenamiento por precio o fecha (por defecto)
        if sort_by == "price_asc":
            query = query.order_by(Service.price.asc())
        elif sort_by == "price_desc":
            query = query.order_by(Service.price.desc())
        else:
            query = query.order_by(Service.fecha_creacion.desc())

        # Paginación
        offset_val = (page - 1) * page_size
        query = query.limit(page_size).offset(offset_val)

        result = await self.db.execute(query)
        services = list(result.scalars().all())

        await self._attach_ratings(services)

        # Calcular distancia exacta y filtrar en Python
        if lat is not None and lng is not None and radius is not None:
            filtered = []
            for s in services:
                if s.latitude is not None and s.longitude is not None:
                    d = _haversine(lat, lng, s.latitude, s.longitude)
                    if d <= radius:
                        s.distance = d
                        filtered.append(s)
                else:
                    filtered.append(s)
            # Ordenar por distancia
            filtered.sort(key=lambda s: getattr(s, 'distance', float('inf')))
            return filtered

        return services

    async def get_by_id(self, service_id: uuid.UUID) -> Service | None:
        result = await self.db.execute(
            select(Service).options(selectinload(Service.images)).where(Service.id == service_id)
        )
        s = result.scalar_one_or_none()
        if s:
            await self._attach_ratings([s])
        return s

    async def get_by_provider(
        self, provider_id: uuid.UUID, page: int = 1, page_size: int = 20
    ) -> tuple[list[Service], int]:
        count_stmt = select(func.count(Service.id)).where(Service.provider_id == provider_id)
        total_result = await self.db.execute(count_stmt)
        total: int = total_result.scalar() or 0

        offset = (page - 1) * page_size
        result = await self.db.execute(
            select(Service).options(selectinload(Service.images))
            .where(Service.provider_id == provider_id)
            .order_by(Service.fecha_creacion.desc())
            .limit(page_size)
            .offset(offset)
        )
        services = list(result.scalars().all())
        await self._attach_ratings(services)
        return services, total

    async def create(self, service: Service) -> Service:
        self.db.add(service)
        await self.db.flush()
        await self.db.refresh(service)
        return service

    async def update(self, service: Service, data: dict) -> Service:
        for field, value in data.items():
            if value is not None:
                setattr(service, field, value)
        await self.db.flush()
        await self.db.refresh(service)
        return service

    async def delete(self, service: Service) -> None:
        await self.db.delete(service)
        await self.db.flush()
