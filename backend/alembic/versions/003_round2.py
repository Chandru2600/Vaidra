"""Round 2 - partners, enquiries, Family Relay, subscriptions

Revision ID: 003_round2
Revises: 002_emergency_features
Create Date: 2026-11-25
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect

revision = '003_round2'
down_revision = '002_emergency_features'
branch_labels = None
depends_on = None


def _table_exists(inspector, name):
    return name in inspector.get_table_names()


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)

    if not _table_exists(inspector, 'partners'):
        op.create_table(
            'partners',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('org_type', sa.String(), nullable=False),
            sa.Column('org_name', sa.String(), nullable=False),
            sa.Column('address', sa.Text(), nullable=True),
            sa.Column('phone', sa.String(), nullable=True),
            sa.Column('specialities', sa.Text(), nullable=True),
            sa.Column('hours_text', sa.Text(), nullable=True),
            sa.Column('emergency_facilities', sa.Text(), nullable=True),
            sa.Column('services', sa.Text(), nullable=True),
            sa.Column('verification_status', sa.String(), nullable=False, server_default='pending'),
            sa.Column('verified_by', sa.Integer(), nullable=True),
            sa.Column('er_status', sa.String(), nullable=True),
            sa.Column('icu_beds_available', sa.Integer(), nullable=True),
            sa.Column('general_beds_available', sa.Integer(), nullable=True),
            sa.Column('diagnostics_available', sa.Text(), nullable=True),
            sa.Column('specialists_available', sa.Text(), nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.ForeignKeyConstraint(['verified_by'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_partners_id', 'partners', ['id'], unique=False)
        op.create_index('ix_partners_user_id', 'partners', ['user_id'], unique=True)

    if not _table_exists(inspector, 'enquiries'):
        op.create_table(
            'enquiries',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('partner_id', sa.Integer(), nullable=False),
            sa.Column('kind', sa.String(), nullable=False),
            sa.Column('message', sa.Text(), nullable=False),
            sa.Column('status', sa.String(), nullable=False, server_default='open'),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.ForeignKeyConstraint(['partner_id'], ['partners.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_enquiries_id', 'enquiries', ['id'], unique=False)
        op.create_index('ix_enquiries_partner_id', 'enquiries', ['partner_id'], unique=False)
        op.create_index('ix_enquiries_user_id', 'enquiries', ['user_id'], unique=False)

    if not _table_exists(inspector, 'family_groups'):
        op.create_table(
            'family_groups',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('name', sa.String(), nullable=False),
            sa.Column('owner_id', sa.Integer(), nullable=False),
            sa.Column('invite_code', sa.String(), nullable=False),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['owner_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_family_groups_id', 'family_groups', ['id'], unique=False)
        op.create_index('ix_family_groups_invite_code', 'family_groups', ['invite_code'], unique=True)
        op.create_index('ix_family_groups_owner_id', 'family_groups', ['owner_id'], unique=False)

    if not _table_exists(inspector, 'family_members'):
        op.create_table(
            'family_members',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('group_id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('can_share_location', sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column('joined_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['group_id'], ['family_groups.id']),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id'),
            sa.UniqueConstraint('group_id', 'user_id', name='uq_family_member_group_user')
        )
        op.create_index('ix_family_members_id', 'family_members', ['id'], unique=False)
        op.create_index('ix_family_members_group_id', 'family_members', ['group_id'], unique=False)
        op.create_index('ix_family_members_user_id', 'family_members', ['user_id'], unique=False)

    if not _table_exists(inspector, 'family_incidents'):
        op.create_table(
            'family_incidents',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('group_id', sa.Integer(), nullable=False),
            sa.Column('reporter_id', sa.Integer(), nullable=False),
            sa.Column('title', sa.String(), nullable=False),
            sa.Column('description', sa.Text(), nullable=True),
            sa.Column('status', sa.String(), nullable=False, server_default='active'),
            sa.Column('hospital_destination', sa.String(), nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['group_id'], ['family_groups.id']),
            sa.ForeignKeyConstraint(['reporter_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_family_incidents_id', 'family_incidents', ['id'], unique=False)
        op.create_index('ix_family_incidents_group_id', 'family_incidents', ['group_id'], unique=False)
        op.create_index('ix_family_incidents_reporter_id', 'family_incidents', ['reporter_id'], unique=False)

    if not _table_exists(inspector, 'incident_updates'):
        op.create_table(
            'incident_updates',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('incident_id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('message', sa.Text(), nullable=False),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.ForeignKeyConstraint(['incident_id'], ['family_incidents.id']),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_incident_updates_id', 'incident_updates', ['id'], unique=False)
        op.create_index('ix_incident_updates_incident_id', 'incident_updates', ['incident_id'], unique=False)
        op.create_index('ix_incident_updates_user_id', 'incident_updates', ['user_id'], unique=False)

    if not _table_exists(inspector, 'subscriptions'):
        op.create_table(
            'subscriptions',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('plan', sa.String(), nullable=False),
            sa.Column('status', sa.String(), nullable=False, server_default='pending_payment'),
            sa.Column('started_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
            sa.Column('valid_until', sa.DateTime(timezone=True), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id']),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index('ix_subscriptions_id', 'subscriptions', ['id'], unique=False)
        op.create_index('ix_subscriptions_user_id', 'subscriptions', ['user_id'], unique=True)


def downgrade() -> None:
    op.drop_table('subscriptions')
    op.drop_table('incident_updates')
    op.drop_table('family_incidents')
    op.drop_table('family_members')
    op.drop_table('family_groups')
    op.drop_table('enquiries')
    op.drop_table('partners')
