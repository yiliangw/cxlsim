#!/bin/bash

. `dirname ${BASH_SOURCE[0]}`/../passwdrc 

# Use sed to replcace all {{X}} with the value of X
vars=(
  ADMIN_PASS
  BAIZE_PASS
  GLANCE_PASS
  PLACEMENT_PASS
  NOVA_PASS
  NEUTRON_PASS
  RABBIT_PASS
  METADATA_SECRET
  KEYSTONE_DBPASS
  GLANCE_DBPASS
  PLACEMENT_DBPASS
  NOVA_DBPASS
  NEUTRON_DBPASS
)

sed_exprs=""
for var in ${vars[@]}; do
  sed_exprs="${sed_exprs} s/{{${var}}}/${!var}/g;"
done

sed -e "${sed_exprs}" $@
