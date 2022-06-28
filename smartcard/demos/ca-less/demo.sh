#!/bin/bash -x

set -e

dnf -y install ipa-server-dns

ipa-server-install --domain ipa.test --realm IPA.TEST \
  --setup-dns --auto-forwarders \
  -a Secret123 -p Secret123 \
  --ca-cert-file=/opt/test_ca/rootCA.crt \
  --ca-cert-file=/opt/test_ca/intermediate/intermediateCA.crt \
  --dirsrv-cert-file=/opt/test_ca/intermediate/server.crt \
  --dirsrv-cert-file=/opt/test_ca/intermediate/server.key \
  --dirsrv-pin=Secret123 \
  --http-cert-file=/opt/test_ca/intermediate/server.crt \
  --http-cert-file=/opt/test_ca/intermediate/server.key \
  --http-pin=Secret123 \
  --pkinit-cert-file=/opt/test_ca/intermediate/server-kdc.crt \
  --pkinit-cert-file=/opt/test_ca/intermediate/server-kdc.key \
  --pkinit-pin=Secret123 \
  -U

