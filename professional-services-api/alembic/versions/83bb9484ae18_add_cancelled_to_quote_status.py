"""add_cancelled_to_quote_status

Revision ID: 83bb9484ae18
Revises: 15bf48a08be7
Create Date: 2026-05-15 16:19:50.989619

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '83bb9484ae18'
down_revision: Union[str, Sequence[str], None] = '15bf48a08be7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Esta línea le dice a PostgreSQL que añada 'cancelled' al tipo de dato existente
    op.execute("COMMIT") # Necesario en Postgres para alterar ENUMS
    op.execute("ALTER TYPE quotestatus ADD VALUE 'cancelled'")


def downgrade() -> None:
    """Downgrade schema."""
    pass
