Certificate Basics Demo
=======================

This Demo is meant as a learning and testing tool only.  It is not
intended for Production use.

In this directory, I provide both a shell script and a set of Ansible
Playbooks to setup a CA and user certificate.

The CA is self-signed and is meant for testing only.

Shell Script
------------

* demo.sh -- uses openssl commands to setup a CA and issue a user
             certificate


Ansible Playbooks
-----------------

* setup_ca.yaml -- Creates CA in /opt/test_ca by default
* issue_user_cert.yaml -- Gen Key and Issue a user certificate
* ca.cnf.j2 -- template for openssl config file for CA
* user.cnd.j2 -- template for openssl config for certificate request


Install and Usage
-----------------

* git clone https://github.com/spoore1/notes.git
* cd notes/smartcard/demos/certificate_basics

Run Shell Script
----------------

* sh demo.sh

Run Playbooks
-------------

* First set your host in hosts inventory file
* ansible-playbook -v -i hosts setup_ca.yaml
* ansible-playbook -v -i hosts issue_user_cert.yaml
    * can change some variables:
    * --extra-vars '{"ca_dir": "/path/to/cadir", "username": "jdoe"}' 
