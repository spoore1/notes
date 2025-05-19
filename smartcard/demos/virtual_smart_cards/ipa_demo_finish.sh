#!/bin/bash
# 
# be sure to copy user cert/key files into TESTDIR

TESTDIR=/opt/virtual_smartcard
NAME=ipauser1
PIN="123456"
export SOFTHSM2_CONF="$TESTDIR/softhsm2.conf"

pushd $TESTDIR

if [ ! -f ${TESTDIR}/${NAME}.key ]; then
    echo "Could not find ${TESTDIR}/${NAME}.key"
    echo "Creating user, key, and certificate"
    echo Secret123|kinit admin
    ipa user-add --first=f --last=l ${NAME}
    openssl req -new -newkey rsa:2048 -keyout ${NAME}.key \
        -nodes -out ${NAME}.csr -subj "/CN=${NAME}"
    ipa cert-request ${NAME}.csr --principal=${NAME} \
        --certificate-out=${NAME}.crt
fi

pkcs11-tool --module libsofthsm2.so --slot-index 0 -w ${NAME}.key -y privkey \
    --label ${NAME} -p $PIN --set-id 0 -d 0

pkcs11-tool --module libsofthsm2.so --slot-index 0 -w ${NAME}.crt -y cert \
        --label ${NAME} -p $PIN --set-id 0 -d 0

systemctl restart pcscd virt_cacard
