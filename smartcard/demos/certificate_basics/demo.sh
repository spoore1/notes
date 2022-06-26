#!/bin/bash

set -e

TESTDIR=/opt/test_ca

dnf -y install openssl

###############################################################################
# Setup local openssl CA
###############################################################################
mkdir $TESTDIR
pushd $TESTDIR

cat > ca.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir              = .
database         = \$dir/index.txt
new_certs_dir    = \$dir/newcerts

certificate      = \$dir/rootCA.crt
serial           = \$dir/serial
private_key      = \$dir/rootCA.key
RANDFILE         = \$dir/rand

default_days     = 365
default_crl_hours = 1
default_md       = sha256

policy           = policy_any
email_in_dn      = no

name_opt         = ca_default
cert_opt         = ca_default
copy_extensions  = copy

[ usr_cert ]
authorityKeyIdentifier = keyid, issuer

[ v3_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
basicConstraints       = CA:true
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign

[ policy_any ]
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
emailAddress           = optional

[ req ]
distinguished_name = req_distinguished_name
prompt             = no

[ req_distinguished_name ]
O  = Example
OU = Example Test
CN = Example Test CA
EOF

for dir in certs crl newcerts; do mkdir $dir; done
touch serial index.txt crlnumber index.txt.attr

#echo 01 > serial
openssl rand -hex 16 > serial

openssl genrsa -out rootCA.key 2048

openssl req -batch -config ca.cnf \
    -x509 -new -nodes -key rootCA.key -sha256 -days 10000 \
    -set_serial 0 -extensions v3_ca -out rootCA.crt

openssl ca -config ca.cnf -gencrl -out crl/root.crl

mkdir -p /etc/sssd/pki
cat $TESTDIR/rootCA.crt >> /etc/sssd/pki/sssd_auth_ca_db.pem
