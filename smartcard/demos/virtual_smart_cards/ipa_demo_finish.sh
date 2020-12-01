#!/bin/bash
# 
# be sure to copy user cert/key files into TESTDIR

TESTDIR=/opt/virtual_smartcard

pushd $TESTDIR

if [ ! -f ${TESTDIR}/${NAME}.key ]; then
    echo "Could not find ${TESTDIR}/${NAME}.key"
    exit 1
fi

PIN="123456"
NAME=ipauser1

export SOFTHSM2_CONF="$TESTDIR/softhsm2.conf"

pkcs11-tool --module libsofthsm2.so --slot-index 0 -w ${NAME}.key -y privkey \
    --label ${NAME} -p $PIN --set-id 0 -d 0

pkcs11-tool --module libsofthsm2.so --slot-index 0 -w ${NAME}.crt -y cert \
        --label ${NAME} -p $PIN --set-id 0 -d 0
