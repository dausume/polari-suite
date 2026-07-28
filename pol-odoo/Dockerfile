# Odoo 18 Community — ERP server for business SIMULATIONS (odoo_sim) and
# REAL business ops (odoo_ops); ODOO_INTEGRATION_PLAN.md. Pinned dated tag
# (od-0: Community 18): upgrades migrate the database, so a version bump
# is its own receipted move — never a silent FROM change.
FROM odoo:18.0-20260723

# DB connection arrives via env_file (pol-odoo/odoo.env — official image
# entrypoint reads HOST/PORT/USER/PASSWORD). Server config is the mounted
# pol-odoo/odoo.conf (NO secrets).

# od-2 SSO: OCA auth_oidc (OpenID Connect code flow against Keycloak),
# pinned like the base image. The wheel lands in site-packages and Odoo
# discovers it through the odoo.addons namespace; it is INSTALLED into a
# database by `pol odoo sso-setup` (or init-db thereafter), never here.
USER root
RUN pip3 install --no-cache-dir --break-system-packages \
    odoo-addon-auth_oidc==18.0.1.1.0.2
USER odoo
