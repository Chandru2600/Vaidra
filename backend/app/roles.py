"""Roles & role-based access control (checklist §9).

Roles (stored as plain strings on User.role, same convention as the
pre-existing DOCTOR role):
- CITIZEN (default) — ordinary app user
- DOCTOR — pre-existing, can view assigned cases
- HOSPITAL_PARTNER / PHARMACY_PARTNER — partner portal accounts (§9)
- ADMIN — verifies/rejects partners, manages the platform

Admin assignment: set the environment variable VAIDRA_ADMIN_EMAIL to the
email address of the admin user. When a user registers or logs in with
exactly that email (case-insensitive), their role is promoted to ADMIN
automatically. There is NO hardcoded admin password and NO default admin
account — without the env var, nobody is an admin.

DO NOT put a real admin email in the repo or in any committed file.
"""
import os

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import models, utils
from app.db import get_db

ROLE_CITIZEN = "CITIZEN"
ROLE_DOCTOR = "DOCTOR"
ROLE_HOSPITAL_PARTNER = "HOSPITAL_PARTNER"
ROLE_PHARMACY_PARTNER = "PHARMACY_PARTNER"
ROLE_ADMIN = "ADMIN"

ALL_ROLES = {
    ROLE_CITIZEN,
    ROLE_DOCTOR,
    ROLE_HOSPITAL_PARTNER,
    ROLE_PHARMACY_PARTNER,
    ROLE_ADMIN,
}


def admin_email_configured() -> str:
    """The admin email from the environment (empty string = no admin)."""
    return (os.environ.get("VAIDRA_ADMIN_EMAIL") or "").strip().lower()


def maybe_promote_admin(user: models.User, db: Session) -> models.User:
    """Promote a user to ADMIN if their email matches VAIDRA_ADMIN_EMAIL.

    Called on register and on login, so the admin account is recognised
    even if it was created before the env var was set.
    """
    admin_email = admin_email_configured()
    if not admin_email:
        return user
    if (user.email or "").strip().lower() == admin_email:
        if (user.role or "").upper() != ROLE_ADMIN:
            user.role = ROLE_ADMIN
            db.commit()
            db.refresh(user)
    return user


def get_current_user(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(utils.get_current_user_id),
) -> models.User:
    """Load the authenticated user row (404 if the token's user is gone)."""
    user = db.query(models.User).filter(models.User.id == current_user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    return user


def require_role(*allowed_roles: str):
    """Dependency factory: only users whose role is in allowed_roles pass.

    Example: Depends(require_role("ADMIN")) — anyone else gets 403.
    Role comparison is case-insensitive.
    """

    allowed = {r.upper() for r in allowed_roles}

    def _checker(user: models.User = Depends(get_current_user)) -> models.User:
        if (user.role or ROLE_CITIZEN).upper() not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: requires role {', '.join(sorted(allowed))}",
            )
        return user

    return _checker
