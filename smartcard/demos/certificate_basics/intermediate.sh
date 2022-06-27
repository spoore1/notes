TESTDIR=/opt/test_ca/intermediate

set -e

mkdir $TESTDIR
pushd $TESTDIR

for dir in certs crl newcerts; do mkdir $dir; done
touch serial index.txt crlnumber index.txt.attr
openssl rand -hex 16 > serial

cat > intermediateCA.cnf <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir              = $TESTDIR
database         = \$dir/index.txt
new_certs_dir    = \$dir/newcerts

certificate      = \$dir/intermediateCA.crt
serial           = \$dir/serial
private_key      = \$dir/intermediateCA.key
RANDFILE         = \$dir/rand

default_days     = 3650
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

[ v3_intermediate_ca ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true, pathlen:0
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
CN = Example Test Intermediate CA
EOF

openssl genrsa -out intermediateCA.key 2048

openssl req -batch -config intermediateCA.cnf \
    -new -nodes -key intermediateCA.key -sha256 -days 5000 \
    -extensions v3_intermediate_ca -out intermediateCA.csr

pushd /opt/test_ca

openssl ca -config ca.cnf -extensions v3_ca \
    -batch -notext -days 5000 -md sha256 \
    -in intermediate/intermediateCA.csr \
    -out intermediate/intermediateCA.crt

popd

mkdir -p /etc/sssd/pki
cat $TESTDIR/intermediateCA.crt >> /etc/sssd/pki/sssd_auth_ca_db.pem

############## server certificate

cat > server.cnf <<EOF
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[ req_distinguished_name ]
O = IdM Example
OU = IdM Example Test
CN = $(hostname)

[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = $(hostname)
EOF

openssl genrsa -passout pass:Secret123 -out server.key 4096
openssl req -new -passin pass:Secret123 -key server.key \
    -reqexts req_ext -config server.cnf -out server.csr
openssl ca -config intermediateCA.cnf -batch -notext -keyfile intermediateCA.key \
    -extensions v3_ca -extfile server.cnf \
    -in server.csr -days 365 -out server.crt

############## server KDC certificate

cat > server-kdc.cnf <<EOF
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[ req_distinguished_name ]
O = IdM Example
OU = IdM Example Test KDC
CN = $(hostname)

[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
extendedKeyUsage = serverAuth, clientAuth, codeSigning, emailProtection
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = $(hostname)

[kdc_cert]
basicConstraints=CA:FALSE
keyUsage=nonRepudiation,digitalSignature,keyEncipherment,keyAgreement
extendedKeyUsage=1.3.6.1.5.2.3.5
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
issuerAltName=issuer:copy
subjectAltName=otherName:1.3.6.1.5.2.2;SEQUENCE:kdc_princ_name

[kdc_princ_name]
realm=EXP:0,GeneralString:\${ENV::REALM}
principal_name=EXP:1,SEQUENCE:kdc_principal_seq

[kdc_principal_seq]
name_type=EXP:0,INTEGER:1
name_string=EXP:1,SEQUENCE:kdc_principals

[kdc_principals]
princ1=GeneralString:krbtgt
princ2=GeneralString:\${ENV::REALM}
EOF

openssl genrsa -passout pass:Secret123 -out server-kdc.key 2048

env REALM=IPA.TEST openssl req -new -passin pass:Secret123 -key server-kdc.key \
    -config server-kdc.cnf -out server-kdc.csr

env REALM=IPA.TEST openssl ca \
    -config intermediateCA.cnf \
    -batch -notext \
    -keyfile intermediateCA.key \
    -extensions kdc_cert -extfile server-kdc.cnf \
    -in server-kdc.csr -days 3650 -out server-kdc.crt

############## localuser1 certificate

NAME=localuser1

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

openssl ca -config intermediateCA.cnf -batch -notext \
    -keyfile intermediateCA.key -in ${NAME}.csr -days 365 \
    -extensions usr_cert -out ${NAME}.crt
