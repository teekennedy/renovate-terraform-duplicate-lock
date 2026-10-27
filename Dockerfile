# Self-hosted Renovate with the terraform CLI, so `terraform providers lock`
# can run as a postUpgradeTask.
FROM ghcr.io/renovatebot/renovate:44.190.0

USER root
RUN install-tool terraform 1.17.0
USER 12021
