from pydantic import AliasChoices, BaseModel, ConfigDict, Field
from typing import List, Optional
from datetime import datetime
import uuid

class DashboardSummary(BaseModel):
    ingresos_totales: float = Field(
        ...,
        validation_alias=AliasChoices("ingresos_totales", "total_revenue"),
        serialization_alias="total_revenue",
    )
    tasa_conversion: float = Field(
        ...,
        validation_alias=AliasChoices("tasa_conversion", "conversion_rate"),
        serialization_alias="conversion_rate",
    )
    usuarios_nuevos_7d: int = Field(
        ...,
        validation_alias=AliasChoices("usuarios_nuevos_7d", "new_users_7d"),
        serialization_alias="new_users_7d",
    )
    total_usuarios: int = Field(
        ...,
        validation_alias=AliasChoices("total_usuarios", "total_users"),
        serialization_alias="total_users",
    )
    total_proveedores: int = Field(
        ...,
        validation_alias=AliasChoices("total_proveedores", "total_providers"),
        serialization_alias="total_providers",
    )
    total_servicios: int = Field(
        ...,
        validation_alias=AliasChoices("total_servicios", "total_services"),
        serialization_alias="total_services",
    )
    total_bookings: int
    proveedores_verificados: int = Field(
        ...,
        validation_alias=AliasChoices("proveedores_verificados", "verified_providers"),
        serialization_alias="verified_providers",
    )
    usuarios_suspendidos: int = Field(
        ...,
        validation_alias=AliasChoices("usuarios_suspendidos", "suspended_users"),
        serialization_alias="suspended_users",
    )

    model_config = ConfigDict(populate_by_name=True)

class TopService(BaseModel):
    service_id: uuid.UUID
    title: str
    average_rating: float
    total_reviews: int
    provider_name: str

class TopProvider(BaseModel):
    provider_id: uuid.UUID
    nombre: str = Field(
        ...,
        validation_alias=AliasChoices("nombre", "name"),
        serialization_alias="name",
    )
    email: str
    total_services: int
    total_bookings_completed: int
    total_revenue: float
    average_rating: Optional[float] = None

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

class AdminDashboardResponse(BaseModel):
    summary: DashboardSummary
    top_services: List[TopService]

    model_config = ConfigDict(from_attributes=True)
