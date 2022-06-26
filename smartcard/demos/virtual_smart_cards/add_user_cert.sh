#!/bin/bash
# 
# be sure to copy user cert/key files into TESTDIR

TESTDIR=/opt/virtual_smartcard
CADIR=/opt/test_ca/intermediate
NAME=localuser1
SOPIN="12345678"
PIN="123456"

pushd $TESTDIR

if [ ! -f ${CADIR}/${NAME}.key ]; then
    echo "Could not find ${CADIR}/${NAME}.key"
    exit 1
fi

export SOFTHSM2_CONF="$TESTDIR/softhsm2.conf"

if [ -d $TESTDIR/tokens ]; then
    rm -rf $TESTDIR/tokens
    mkdir $TESTDIR/tokens
fi

softhsm2-util --init-token --slot 0 --label "SC test" --so-pin="$SOPIN" --pin="$PIN"

pkcs11-tool --module libsofthsm2.so --slot-index 0 -w ${CADIR}/${NAME}.key -y privkey \
    --label ${NAME} -p $PIN --set-id 0 -d 0

pkcs11-tool --module libsofthsm2.so --slot-index 0 -w ${CADIR}/${NAME}.crt -y cert \
        --label ${NAME} -p $PIN --set-id 0 -d 0

systemctl start virt_cacard pcscd
