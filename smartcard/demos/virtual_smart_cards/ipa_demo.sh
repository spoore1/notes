#!/bin/bash

TESTDIR=/opt/virtual_smartcard

# Needed on RHEL8:
dnf -y module reset idm
dnf -y module enable idm:DL1
dnf -y install opensc openssl gnutls-utils softhsm nss-tools
dnf -y copr enable jjelen/vsmartcard
dnf -y install virt_cacard vpcd

mkdir -p $TESTDIR
pushd $TESTDIR

PACKAGE="opensc"
SOPIN="12345678"
PIN="123456"
export GNUTLS_PIN=$PIN
GENERATE_KEYS=1
PKCS11_TOOL="pkcs11-tool"
NSSDB=$TESTDIR/db

P11LIB="/usr/lib64/pkcs11/libsofthsm2.so"

cat > $TESTDIR/softhsm2.conf <<EOF
directories.tokendir = $TESTDIR/tokens/
slots.removable = true
objectstore.backend = file
log.level = INFO
EOF

mkdir $TESTDIR/tokens

export SOFTHSM2_CONF="$TESTDIR/softhsm2.conf"

softhsm2-util --init-token --slot 0 --label "SC test" --so-pin="$SOPIN" --pin="$PIN"

mkdir $NSSDB

modutil -create -dbdir sql:$NSSDB -force

modutil -list -dbdir sql:$NSSDB | grep 'library name: p11-kit-proxy.so'
if [ "$?" = "1" ]; then
    modutil -force -add 'SoftHSM PKCS#11' -dbdir sql:$NSSDB -libfile $P11LIB
fi

echo "disable-in: virt_cacard" >> /usr/share/p11-kit/modules/opensc.module

###############################################################################

# This was needed iirc for one of the below projects:

cat > virtcacard.cil <<EOF
(allow pcscd_t node_t (tcp_socket (node_bind)))

EOF

semodule -i virtcacard.cil


###############################################################################

# disable auto-exit for pcscd.service

cp /usr/lib/systemd/system/pcscd.service /etc/systemd/system/
sed -i 's/ --auto-exit//' /etc/systemd/system/pcscd.service 
systemctl daemon-reload
systemctl restart pcscd

# create virt_cacard service

cat > /etc/systemd/system/virt_cacard.service <<EOF
[Unit]
Description=virt_cacard Service
Requires=pcscd.service

[Service]
Environment=SOFTHSM2_CONF="$TESTDIR/softhsm2.conf"
WorkingDirectory=$TESTDIR
ExecStart=/usr/bin/virt_cacard >> /var/log/virt_cacard.debug 2>&1
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable virt_cacard
systemctl restart pcscd virt_cacard
