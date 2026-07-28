# Odoo 18 Community — ERP server for business SIMULATIONS (odoo_sim) and
# REAL business ops (odoo_ops); ODOO_INTEGRATION_PLAN.md. Pinned dated tag
# (od-0: Community 18): upgrades migrate the database, so a version bump
# is its own receipted move — never a silent FROM change.
FROM odoo:18.0-20260723

# DB connection arrives via env_file (pol-odoo/odoo.env — official image
# entrypoint reads HOST/PORT/USER/PASSWORD). Server config is the mounted
# pol-odoo/odoo.conf (NO secrets). od-2 adds the auth_oidc addon here.
