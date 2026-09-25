#!/bin/bash
set -x
trap 'echo "FATAL: setup failed at line ${LINENO}" >> /tmp/progress.log; exit 1' ERR

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Setup build host for day2 lab" > /tmp/progress.log
chmod 666 /tmp/progress.log

# Not on EUS image, this will fail
# Register and install git before library fetch
#dnf -y remove katello-ca-consumer-* 2>/dev/null || true
#subscription-manager clean
#subscription-manager register --activationkey="${ACTIVATION_KEY}" --org="${ORG_ID}" --force
#dnf install -y git podman skopeo

LIBDIR=/tmp/lab-lib-$$
git clone --depth=1 https://github.com/rhel-labs/lab-setup "${LIBDIR}"
. "${LIBDIR}/common.sh"

# Fetch setup files from the lab git repository
fetch_setup_files content/modules/ROOT/examples/flask
echo "Setup files staged" >> /tmp/progress.log

# Copy Flask app files
mkdir -p /home/rhel/flask
cp $SETUP_FILES/* /home/rhel/flask/
chown -R rhel:rhel /home/rhel/flask
echo "Flask app files copied" >> /tmp/progress.log

# Generate Caddyfile with the provisioned hostname so Caddy issues a cert for the correct SNI
mkdir -p /home/rhel/webserver
cat > /home/rhel/webserver/Caddyfile << EOF
{
	auto_https disable_redirects
}

caddy-${GUID}.${DOMAIN}:8443 {
	tls internal
	reverse_proxy localhost:8080
}
EOF
chown -R rhel:rhel /home/rhel/webserver
echo "Caddyfile generated" >> /tmp/progress.log

# Pre-pull base images into rhel user's podman storage
pull_public_images rhel "registry.access.redhat.com/ubi10/ubi" \
 "registry.access.redhat.com/hi/python:3.14-builder" \
 "registry.access.redhat.com/hi/python:3.14" \
 "registry.access.redhat.com/hi/python:3.14-fips" \
 "registry.access.redhat.com/hi/python:3.14-fips-builder" \
 "registry.access.redhat.com/hi/core-runtime:latest-builder" \
 "registry.access.redhat.com/hi/caddy:latest" \
 "registry.access.redhat.com/hi/curl:latest" \
 "registry.access.redhat.com/hi/curl:latest-builder" \
 "ghcr.io/rhel-labs/rhhi-demo:ubi"
echo "Base images pre-pulled" >> /tmp/progress.log

cleanup_subscription
cleanup_tmpfiles
echo "Setup complete" >> /tmp/progress.log
