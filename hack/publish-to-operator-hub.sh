#!/bin/bash

# Create PR to Publish to community-operators and community-operators-prod
#
# * Create upstream ascender-operator release
# * Check out tag (1.1.2).
# * Run VERSION=1.1.2 make bundle
# * Clone https://github.com/k8s-operatorhub/community-operators --branch main
# * mkdir -p operators/ascender-operator/0.31.0/
# * Copy in manifests/ metadata/ and tests/ directories into operators/ascender-operator/1.1.2/
# * Use sed to add in a replaces or skip entry. replace by default.
# * No need to update config.yaml
# * Build and Push operator and bundle images
# * Open PR or at least push to a branch so that a PR can be manually opened from it.
#
# Usage:
#   First, check out ascender-operator tag you intend to release, in this case, 1.0.0
#   $ VERSION=1.1.2 PREV_VERSION=1.1.1 FORK=<your-fork> ./hack/publish-to-operator-hub.sh
#
# Remember to change update the VERSION and PREV_VERSION before running!!!

set -e

VERSION=${VERSION:-$(make print-VERSION)}
PREV_VERSION=${PREV_VERSION:-$(make print-PREV_VERSION)}

BRANCH=publish-ascender-operator-$VERSION
FORK=${FORK:-ascender-auto}
GITHUB_TOKEN=${GITHUB_TOKEN:-$ASCENDER_AUTO_GITHUB_TOKEN}

IMG_REPOSITORY=${IMG_REPOSITORY:-ghcr.io/ctrliq}

OPERATOR_IMG=$IMG_REPOSITORY/ascender-operator:$VERSION
CATALOG_IMG=$IMG_REPOSITORY/ascender-operator-catalog:$VERSION
BUNDLE_IMG=$IMG_REPOSITORY/ascender-operator-bundle:$VERSION

COMMUNITY_OPERATOR_GITHUB_ORG=${COMMUNITY_OPERATOR_GITHUB_ORG:-k8s-operatorhub}
COMMUNITY_OPERATOR_PROD_GITHUB_ORG=${COMMUNITY_OPERATOR_PROD_GITHUB_ORG:-redhat-openshift-ecosystem}

# Build bundle directory
make bundle IMG=$OPERATOR_IMG

# Build bundle and catalog images
make bundle-build bundle-push BUNDLE_IMG=$BUNDLE_IMG IMG=$OPERATOR_IMG
make catalog-build catalog-push CATALOG_IMG=$CATALOG_IMG BUNDLE_IMGS=$BUNDLE_IMG BUNDLE_IMG=$BUNDLE_IMG IMG=$OPERATOR_IMG

# Set containerImage & namespace variables in CSV
sed -i.bak -e "s|containerImage: ghcr.io/ctrliq/ascender-operator:latest|containerImage: ${OPERATOR_IMG}|g" bundle/manifests/ascender-operator.clusterserviceversion.yaml
sed -i.bak -e "s|namespace: placeholder|namespace: ascender|g" bundle/manifests/ascender-operator.clusterserviceversion.yaml

# Add replaces to dependency graph for upgrade path
if ! grep -qF 'replaces: ascender-operator.v${PREV_VERSION}' bundle/manifests/ascender-operator.clusterserviceversion.yaml; then
  sed -i.bak -e "/version: ${VERSION}/a \\
  replaces: ascender-operator.v$PREV_VERSION" bundle/manifests/ascender-operator.clusterserviceversion.yaml
fi

# Rename CSV to contain version in name
mv bundle/manifests/ascender-operator.clusterserviceversion.yaml bundle/manifests/ascender-operator.v${VERSION}.clusterserviceversion.yaml

# Set Openshift Support Range (bump minKubeVersion in CSV when changing)
if ! grep -qF 'openshift.versions' bundle/metadata/annotations.yaml; then
  sed -i.bak -e "/annotations:/a \\
  com.redhat.openshift.versions: v4.11" bundle/metadata/annotations.yaml
fi

# Remove .bak files from bundle result from sed commands
find bundle -name "*.bak" -type f -delete

echo "-- Create branch on community-operators fork --"
git clone https://github.com/$COMMUNITY_OPERATOR_GITHUB_ORG/community-operators.git

mkdir -p community-operators/operators/ascender-operator/$VERSION/
cp -r bundle/* community-operators/operators/ascender-operator/$VERSION/
pushd community-operators/operators/ascender-operator/$VERSION/

git checkout -b $BRANCH
git add ./
git status

message='operator [N] [CI] ascender-operator'
commitMessage="${message} ${VERSION}"
git commit -m "$commitMessage" -s

git remote add upstream https://$GITHUB_TOKEN@github.com/$FORK/community-operators.git

git push upstream --delete $BRANCH || true
git push upstream $BRANCH

gh pr create \
  --title "operator ascender-operator (${VERSION})" \
  --body "operator ascender-operator (${VERSION})" \
  --base main \
  --head $FORK:$BRANCH \
  --repo $COMMUNITY_OPERATOR_GITHUB_ORG/community-operators
popd

echo "-- Create branch on community-operators-prod fork --"
git clone https://github.com/$COMMUNITY_OPERATOR_PROD_GITHUB_ORG/community-operators-prod.git

mkdir -p community-operators-prod/operators/ascender-operator/$VERSION/
cp -r bundle/* community-operators-prod/operators/ascender-operator/$VERSION/
pushd community-operators-prod/operators/ascender-operator/$VERSION/

git checkout -b $BRANCH
git add ./
git status

message='operator [N] [CI] ascender-operator'
commitMessage="${message} ${VERSION}"
git commit -m "$commitMessage" -s

git remote add upstream https://$GITHUB_TOKEN@github.com/$FORK/community-operators-prod.git

git push upstream --delete $BRANCH || true
git push upstream $BRANCH

gh pr create \
  --title "operator ascender-operator (${VERSION})" \
  --body "operator ascender-operator (${VERSION})" \
  --base main \
  --head $FORK:$BRANCH \
  --repo $COMMUNITY_OPERATOR_PROD_GITHUB_ORG/community-operators-prod
popd
