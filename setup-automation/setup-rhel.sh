#!/bin/bash
USER=rhel

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Starting setup for zt-hardened-images" > /tmp/progress.log

chmod 666 /tmp/progress.log

# Fetch setup files from the lab git repository
TMPDIR=/tmp/lab-setup-$$
git clone --single-branch --branch ${GIT_BRANCH:-main} --no-checkout \
  --depth=1 --filter=tree:0 ${GIT_REPO} $TMPDIR
git -C $TMPDIR sparse-checkout set --no-cone /setup-files
git -C $TMPDIR checkout
SETUP_FILES=$TMPDIR/setup-files

# Copy Flask app files
mkdir -p /home/rhel/flask
cp $SETUP_FILES/flask/app.py /home/rhel/flask/app.py
cp $SETUP_FILES/flask/Containerfile.ubi /home/rhel/flask/Containerfile.ubi
cp $SETUP_FILES/flask/Containerfile.hardened /home/rhel/flask/Containerfile.hardened
cp $SETUP_FILES/flask/Containerfile.fips /home/rhel/flask/Containerfile.fips
chown -R rhel:rhel /home/rhel/flask
echo "Flask app files copied" >> /tmp/progress.log

# Copy Caddy webserver files
mkdir -p /home/rhel/webserver
cp $SETUP_FILES/webserver/Caddyfile /home/rhel/webserver/Caddyfile
chown -R rhel:rhel /home/rhel/webserver
echo "Caddy files copied" >> /tmp/progress.log

# Cleanup sparse checkout
rm -rf $TMPDIR

# Pre-pull base images into rhel user's podman storage
runuser -l rhel -c "podman pull registry.access.redhat.com/ubi9/python-312"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.12-builder"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.12"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.12-fips"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/caddy:latest"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/curl:latest"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/curl:latest-builder"
echo "Base images pre-pulled" >> /tmp/progress.log

echo "Setup complete" >> /tmp/progress.log
