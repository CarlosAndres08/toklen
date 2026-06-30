"""add apellido to users, sort_order to categories

Revision ID: a1b2c3d4e5f6
Revises: 9e8d7c6b5a4f
Create Date: 2026-06-27 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '9e8d7c6b5a4f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('apellido', sa.String(100), nullable=True))
    op.add_column('categories', sa.Column('sort_order', sa.Integer(), nullable=False, server_default='0'))


def downgrade() -> None:
    op.drop_column('categories', 'sort_order')
    op.drop_column('users', 'apellido')
