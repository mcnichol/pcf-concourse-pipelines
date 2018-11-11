#!/bin/bash

if [[ $DEBUG == true ]]; then
  set -ex
else
  set -e
fi

chmod +x om-cli/om-linux
OM_CMD=./om-cli/om-linux

chmod +x ./jq/jq-linux64
JQ_CMD=./jq/jq-linux64

chmod +x ./tile-config-convertor/tile-config-convertor_linux_amd64
TCC_CMD=./tile-config-convertor/tile-config-convertor_linux_amd64

function cleanAndEchoProperties {
  INPUT="properties.json"
  OUTPUT="properties.yml"

  echo "$PROPERTIES" >> $INPUT
  $TCC_CMD -g properties -i $INPUT -o $OUTPUT

  echo "# Properties for $PRODUCT_NAME: are:"
  cat $OUTPUT
  echo ""
}

function cleanAndEchoResources() {
  INPUT="resources.json"
  OUTPUT="resources.yml"

  echo "$RESOURCES" >> $INPUT
  $TCC_CMD -g resources -i $INPUT -o $OUTPUT

  echo "# Resources for $PRODUCT_NAME: are:"
  cat $OUTPUT
  echo ""
}

function cleanAndEchoErrands() {
  echo "# Errands for $PRODUCT_NAME: are:"
  ERRANDS_LIST=""
  for errand in $ERRANDS; do
    if [[ -z "$ERRANDS_LIST" ]]; then
      ERRANDS_LIST=$errand
    else
      ERRANDS_LIST+=,$errand
    fi
  done
  echo $ERRANDS_LIST
  echo ""
}

function applyChangesConfig() {
  APPLY_CHANGES_CONFIG_YML=apply_changes_config.yml

  echo 'apply_changes_config: |' >> "$APPLY_CHANGES_CONFIG_YML"
  echo "  deploy_products: [\"$PRODUCT_NAME:\"]" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "  errands:" >> "$APPLY_CHANGES_CONFIG_YML" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "    $PRODUCT_NAME::" >> "$APPLY_CHANGES_CONFIG_YML"
  echo "      run_post_deploy:" >> "$APPLY_CHANGES_CONFIG_YML"

  for errand in $ERRANDS; do
    echo "        $errand: true" >> "$APPLY_CHANGES_CONFIG_YML"
  done

  echo "  ignore_warnings: true" >> "$APPLY_CHANGES_CONFIG_YML"

  echo "# Apply Changes Config for $PRODUCT_NAME: are:"
  cat $APPLY_CHANGES_CONFIG_YML
  echo ""
}

function echoNetworkTemplate() {
  echo "# Network and AZ's template: "
  echo "network-properties: |
  network:
    name:
  service_network:
    name:
  other_availability_zones:
    - name:
    - name:
  singleton_availability_zone:
    name:"
  echo ""
}

CURL_CMD="$OM_CMD -k -t $OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD curl -s -p"

PRODUCTS=$($CURL_CMD /api/v0/staged/products)
PRODUCT_GUID=$(echo $PRODUCTS | $JQ_CMD -r --arg product_identifier $PRODUCT_NAME: '.[] | select(.type == $product_identifier) | .guid')

## Download the product properties

PROPERTIES=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/properties)

## Download the resources
RESOURCES=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/resources)

## Download the errands
ERRANDS=$($CURL_CMD /api/v0/staged/products/$PRODUCT_GUID/errands | $JQ_CMD -r '.errands[] | select(.post_deploy==true) | .name')

## Cleanup all the stuff, and echo on the console
echo "product-name: $PRODUCT_NAME:"
cleanAndEchoProperties
cleanAndEchoResources
echoNetworkTemplate
cleanAndEchoErrands
applyChangesConfig


## Clean-up the container
rm -rf $PRODUCT_NAME:.json
rm -rf $RESOURCES_YML
