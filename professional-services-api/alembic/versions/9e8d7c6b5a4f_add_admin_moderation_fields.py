"""add admin/moderation fields to users, categories, services

Revision ID: 9e8d7c6b5a4f
Revises: bb1a119640ce
Create Date: 2026-06-27 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


revision: str = '9e8d7c6b5a4f'
down_revision: Union[str, Sequence[str], None] = '9ccb8e0175ce'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # === users ===
    op.add_column('users', sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('users', sa.Column('is_suspended', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('users', sa.Column('suspension_reason', sa.Text(), nullable=True))
    op.add_column('users', sa.Column('ban_date', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('ban_reason', sa.Text(), nullable=True))
    op.add_column('users', sa.Column('last_login', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('login_count', sa.Integer(), nullable=False, server_default='0'))

    # === categories ===
    op.add_column('categories', sa.Column('image_url', sa.String(255), nullable=True))
    op.add_column('categories', sa.Column('icon', sa.String(50), nullable=True))
    op.add_column('categories', sa.Column('slug', sa.String(100), nullable=True, unique=True))
    op.add_column('categories', sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('categories', sa.Column('is_featured', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('categories', sa.Column('is_approved', sa.Boolean(), nullable=False, server_default='true'))

    # === services ===
    op.add_column('services', sa.Column('is_approved', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('services', sa.Column('rejection_reason', sa.Text(), nullable=True))
    op.add_column('services', sa.Column('reported_count', sa.Integer(), nullable=False, server_default='0'))


def downgrade() -> None:
    # === users ===
    op.drop_column('users', 'is_active')
    op.drop_column('users', 'is_suspended')
    op.drop_column('users', 'suspension_reason')
    op.drop_column('users', 'ban_date')
    op.drop_column('users', 'ban_reason')
    op.drop_column('users', 'last_login')
    op.drop_column('users', 'login_count')

    # === categories ===
    op.drop_column('categories', 'image_url')
    op.drop_column('categories', 'icon')
    op.drop_column('categories', 'slug')
    op.drop_column('categories', 'is_active')
    op.drop_column('categories', 'is_featured')
    op.drop_column('categories', 'is_approved')

    # === services ===
    op.drop_column('services', 'is_approved')
    op.drop_column('services', 'rejection_reason')
    op.drop_column('services', 'reported_count')
