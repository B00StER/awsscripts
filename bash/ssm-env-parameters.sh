#!/bin/bash

### (c) Mike Syroezhko
# https://github.com/B00StER/awsscripts
#
# Pulls a collection of Parameter Name - Parameter Value pairs from the SSM Parameter Store by predefined prefix
# and exports each pair as an Environment Variable
#
### Prerequisites:
# - AWS CLI isntalled and configured with access to SSM
# - jq
#
### Usage:
#
# $ . ./ssm-env-parameters
#

SSM_PARAM_PREFIX="/your-app-name"
SSM_PARAM_LIST=$(aws ssm get-parameters-by-path --with-decryption --path "${SSM_PARAM_PREFIX}" | jq -r '.Parameters[]|"\(.Name)=\(.Value)"');

for SSM_PARAM in $SSM_PARAM_LIST; do
  PARAM=${SSM_PARAM#"$SSM_PARAM_PREFIX/"}
  PARAM_STRIP=${PARAM//$'\n'/}
  export "${PARAM}"
done
