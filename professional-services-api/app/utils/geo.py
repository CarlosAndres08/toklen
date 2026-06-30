import math
from typing import Tuple


def haversine(
    lat1: float, lng1: float,
    lat2: float, lng2: float,
) -> float:
    """
    Distancia en kilómetros entre dos puntos geográficos
    usando la fórmula del haversine.
    """
    R = 6371.0  # radio terrestre medio en km
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlng / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)


def in_radius(
    lat1: float, lng1: float,
    lat2: float, lng2: float,
    radius_km: float,
) -> bool:
    """True si la distancia entre ambos puntos es <= radius_km."""
    return haversine(lat1, lng1, lat2, lng2) <= radius_km
