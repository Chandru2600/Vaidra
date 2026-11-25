"""Emergency features - emergency contacts, LifeCards, AI audit logs

Revision ID: 002_emergency_features
Revises: 001_initial
Create Date: 2026-11-25
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '002_emergency_features'
down_revision = '001_initial'
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    existing_tables = inspector.get_table_names()

    if 'emergency_contacts' not in existing_tables:
        op.create_table(
            'emergency_contacts',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('name', sa.String(), nullable=False),
            sa.Column('relationship', sa.String(), nullable=True),
            sa.Column('phone', sa.String(), nullable=False),
            sa.Column('is_primary', sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_emergency_contacts_id', 'emergency_contacts', ['id'], unique=False)
        op.create_index('ix_emergency_contacts_user_id', 'emergency_contacts', ['user_id'], unique=False)

    if 'lifecards' not in existing_tables:
        op.create_table(
            'lifecards',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('blood_group', sa.String(), nullable=True),
            sa.Column('allergies', sa.Text(), nullable=True),
            sa.Column('conditions', sa.Text(), nullable=True),
            sa.Column('medications', sa.Text(), nullable=True),
            sa.Column('notes', sa.Text(), nullable=True),
            sa.Column('preferred_hospital', sa.String(), nullable=True),
            sa.Column('insurance', sa.String(), nullable=True),
            sa.Column('share_with_contacts', sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column('share_token', sa.String(), nullable=False),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_lifecards_id', 'lifecards', ['id'], unique=False)
        op.create_index('ix_lifecards_share_token', 'lifecards', ['share_token'], unique=True)
        op.create_index('ix_lifecards_user_id', 'lifecards', ['user_id'], unique=True)

    if 'ai_interaction_logs' not in existing_tables:
        op.create_table(
            'ai_interaction_logs',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=True),
            sa.Column('scan_id', sa.Integer(), nullable=True),
            sa.Column('model', sa.String(), nullable=False),
            sa.Column('prompt_version', sa.String(), nullable=True),
            sa.Column('result_summary', sa.Text(), nullable=True),
            sa.Column('escalation', sa.String(), nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.ForeignKeyConstraint(['scan_id'], ['scans.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_ai_interaction_logs_id', 'ai_interaction_logs', ['id'], unique=False)
        op.create_index('ix_ai_interaction_logs_scan_id', 'ai_interaction_logs', ['scan_id'], unique=False)
        op.create_index('ix_ai_interaction_logs_user_id', 'ai_interaction_logs', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_table('ai_interaction_logs')
    op.drop_table('lifecards')
    op.drop_table('emergency_contacts')
