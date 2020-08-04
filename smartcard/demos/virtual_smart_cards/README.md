Virtual Smart Cards Demo
========================

This demo will show how you can use Virtual Smart Cards to test when
you do not have physical ones available.  It does make use of some
other projects so results may vary.

This demo is also meant to follow the certificate_basics demo or at 
least you should run that first to setup the test environment before
completing the steps here.

Shell Script
------------

* demo.sh -- sets up system adds user and configures sssd

Ansible Playbooks
-----------------

* setup_virtual_smartcard.yaml -- configure system to use virtual smart cards
* add_user_certs.yaml -- add user cert created by certificate_basics demo
* setup_sssd.yaml -- setup sssd for use

