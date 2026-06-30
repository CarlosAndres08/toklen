"""add location, featured, quote_booking fields

Revision ID: d0c4f1a2b3e4
Revises: 83bb9484ae18
Create Date: 2026-06-22 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision: str = 'd0c4f1a2b3e4'
down_revision: Union[str, Sequence[str], None] = '83bb9484ae18'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # === users ===
    op.add_column('users', sa.Column('latitude', sa.Float(), nullable=True))
    op.add_column('users', sa.Column('longitude', sa.Float(), nullable=True))
    op.add_column('users', sa.Column('service_radius', sa.Float(), nullable=True, server_default='10.0'))
    op.add_column('users', sa.Column('is_available', sa.Boolean(), nullable=False, server_default='true'))

    # === services ===
    op.add_column('services', sa.Column('latitude', sa.Float(), nullable=True))
    op.add_column('services', sa.Column('longitude', sa.Float(), nullable=True))
    op.add_column('services', sa.Column('is_featured', sa.Boolean(), nullable=False, server_default='false'))

    # === bookings ===
    op.add_column('bookings', sa.Column('quote_id', UUID(as_uuid=True), nullable=True))
    op.add_column('bookings', sa.Column('negotiated_price', sa.Float(), nullable=True))
    op.create_foreign_key('fk_bookings_quote_id', 'bookings', 'service_quotes', ['quote_id'], ['id'], ondelete='SET NULL')

    # === service_quotes ===
    op.add_column('service_quotes', sa.Column('booking_id', UUID(as_uuid=True), nullable=True))
    op.create_foreign_key('fk_service_quotes_booking_id', 'service_quotes', 'bookings', ['booking_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    op.drop_column('service_quotes', 'booking_id')
    op.drop_constraint('fk_service_quotes_booking_id', 'service_quotes', type_='foreignkey')
    op.drop_column('bookings', 'negotiated_price')
    op.drop_column('bookings', 'quote_id')
    op.drop_constraint('fk_bookings_quote_id', 'bookings', type_='foreignkey')
    op.drop_column('services', 'is_featured')
    op.drop_column('services', 'longitude')
    op.drop_column('services', 'latitude')
    op.drop_column('users', 'is_available')
    op.drop_column('users', 'service_radius')
    op.drop_column('users', 'longitude')
    op.drop_column('users', 'latitude')
