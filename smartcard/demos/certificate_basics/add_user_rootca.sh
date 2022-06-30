#!/bin/bash

TESTDIR=/opt/test_ca

set -e

if [ ! -d $TESTDIR ]; then
    echo "TESTDIR ($TESTDIR) does not exist. exiting."
    exit 1
fi

pushd $TESTDIR

############## localuser1 certificate

NAME=${1:-localuser1}

echo "Issuing rootCA certificate for user ${NAME}"

if ! id $NAME >/dev/null 2>&1; then
    echo "Local user does not exist...creating"
    useradd -m $NAME
fi

cat > ${NAME}.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
O = IdM Example
OU = IdM Example Test Users
CN = ${NAME}

[ req_exts ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "${NAME}"
subjectKeyIdentifier = hash
keyUsage = critical, nonRepudiation, digitalSignature
extendedKeyUsage = clientAuth, emailProtection, msSmartcardLogin
subjectAltName = otherName:msUPN;UTF8:${NAME}@EXAMPLE.COM, email:${NAME}@example.com
EOF

openssl genrsa -out ${NAME}.key 2048

openssl req -new -nodes -key ${NAME}.key \
    -reqexts req_exts -config ${NAME}.cnf -out ${NAME}.csr

openssl ca -config ca.cnf -batch -notext \
    -keyfile rootCA.key -in ${NAME}.csr -days 365 \
    -extensions usr_cert -out ${NAME}.crt
