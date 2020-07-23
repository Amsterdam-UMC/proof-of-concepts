#!/bin/sh
#
# Science Collaboration Zone (SCZ) Azure Linux Redhat 7.6 automation bash script  V0.991
# A.H.Ullings, copyright 2019, all rights reserved
#
PACKAGES='realmd oddjob oddjob-mkhomedir sssd adcli samba-common-tools krb5-libs krb5-workstation'
HOSTS='/etc/hosts'
SSSDCONFG='/etc/sssd/sssd.conf'
SSHCONFG='/etc/ssh/sshd_config'

#
function fix_etc_hosts {
    if ! grep -q $HOSTNAME $HOSTS
    then
        echo "fixing " $1
        entry="127.0.0.1\t"$HOSTNAME" "$HOSTNAME.$DOMAIN
        echo -e $entry >>$1
    fi
}

#
function patch_etc_sssd {
    if ! test -f $1+; then
        echo "patching " $1
        cat $1 |\
        sed 's/services = nss, pam/services = nss, pam, sudo, ssh/' |\
        sed '/cache_credentials.*/a\entry_cache_timeout = 60' |\
        sed '/cache_credentials.*/a\case_sensitive = Preserving' |\
        sed '/ldap_sasl_authid.*/d' |\
        sed '/ldap_id_mapping.*/a\ldap_group_name = cn' |\
        sed 's/use_fully_qualified_names.*/use_fully_qualified_names = False/' |\
        sed 's/fallback_homedir.*/fallback_homedir = \/home\/%u/' |\
        sed '/access_provider.*/a\\nad_enable_gc = False' |\
        sed '/access_provider.*/a\ldap_use_tokengroups = False' |\
        sed '/access_provider.*/a\ldap_user_ssh_public_key = altSecurityIdentities' |\
        sed '/access_provider.*/a\ldap_user_extra_attrs = altSecurityIdentities:altSecurityIdentities' |\
        cat >$1+
        cp $1 $1-
        cp $1+ $1
    fi
}

#
function patch_etc_sshd {
    if ! test -f $1+; then
        echo "patching " $1
        cat $1 |\
        sed '/#AuthorizedKeysCommandUser nobody/aAuthorizedKeysCommandUser root' |\
        sed '/#AuthorizedKeysCommandUser nobody/aAuthorizedKeysCommand /usr/bin/sss_ssh_authorizedkeys' |\
        sed 's/GSSAPIAuthentication.*/GSSAPIAuthentication no/' |\
        sed 's/#UseDNS.*/UseDNS = no/' |\
        cat >$1+
        cp $1 $1-
        cp $1+ $1
    fi
}

#
export key=$1
DOMAIN=`echo $1 | cut -d@ -f2`
ARG1_UPPERCASE=`echo $1 | tr 'a-z' 'A-Z'`
HOSTNAME=`hostname`
#
fix_etc_hosts $HOSTS
#
# fix some Redhat/Azure solution 3167021 repos certificate issues....
# echo "yum fix 3167021 "
# curl -o azureclient.rpm https://rhui-1.microsoft.com/pulp/repos/microsoft-azure-rhel7/Packages/r/rhui-azure-rhel7-2.2-97.noarch.rpm
# rpm -U azureclient.rpm
# yum clean all
#
# exit
# echo "yum update "
# yum update -y >/dev/null
#
echo "yum install " $PACKAGES
yum install -y $PACKAGES >/dev/null
#
# we would like to reboot at this point..... but at least we restart some services
# systemctl restart realmd
#
echo "kinit " $ARG1_UPPERCASE
kinit $ARG1_UPPERCASE >/dev/null <<EOF
`echo $2 | openssl enc -pbkdf2 -base64 -d -aes-256-cbc -salt -pass env:key`
EOF
echo "realm join " $1
realm join -v -U $1 $DOMAIN >/dev/null 2>/dev/null <<EOF
`echo $2 | openssl enc -pbkdf2 -base64 -d -aes-256-cbc -salt -pass env:key`
EOF
#
# edit /etc/sssd/sssd.conf
patch_etc_sssd $SSSDCONFG
systemctl restart sssd
# sss_cache -E
#
# edit /etc/ssh/sshd_config
patch_etc_sshd $SSHCONFG
systemctl restart sshd
#
# cleanup, should be an on exit trap
# rm -rf $0
exit 0