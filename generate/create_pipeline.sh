#!/bin/bash -e

BASE_DIR=$(dirname "$(realpath $0)")

clis=(jq ytt yq)

set +e
for cli in "${clis[@]}"; do
  cli_exists=$(which $cli)
  if [[ -z "${cli_exists}" ]]; then
    echo "Install ${cli} cli first"
    exit 1
  fi
done

read -p "Enter the pipelines directory: " PIPELINE_DIR

read -p "Enter env name: " ENV
export YTT_env=${ENV}

export ENV_PIPELINE_DIR=${PIPELINE_DIR}/${ENV}

folders=(pipelines pipelines/download-products pipelines/ops-manager pipelines/products pipelines/repave)

for folder in "${folders[@]}"; do
  if [[ ! -d "${folder}" ]]; then
    mkdir -p "${ENV_PIPELINE_DIR}/${folder}"
  fi
done
set -e

ytt -f "${BASE_DIR}/download-products/template.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments > "${ENV_PIPELINE_DIR}/pipelines/download-products/pipeline.yml"
ytt -f "${BASE_DIR}/download-products/template-params.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments --data-values-env YTT > "${ENV_PIPELINE_DIR}/pipelines/download-products/params-template.yml"

ytt -f "${BASE_DIR}/opsman/template.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments > "${ENV_PIPELINE_DIR}/pipelines/ops-manager/pipeline.yml"
ytt -f "${BASE_DIR}/opsman/template-params.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments --data-values-env YTT > "${ENV_PIPELINE_DIR}/pipelines/ops-manager/params-template.yml"

ytt -f "${BASE_DIR}/repave-platform/template.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments --data-values-env YTT > "${ENV_PIPELINE_DIR}/pipelines/repave/pipeline.yml"
ytt -f "${BASE_DIR}/repave-platform/template-params.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments --data-values-env YTT > "${ENV_PIPELINE_DIR}/pipelines/repave/params-template.yml"

ytt -f "${BASE_DIR}/install-upgrade-products/template.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments > "${ENV_PIPELINE_DIR}/pipelines/products/pipeline.yml"
ytt -f "${BASE_DIR}/install-upgrade-products/template-params.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments --data-values-env YTT > "${ENV_PIPELINE_DIR}/pipelines/products/params-template.yml"

ytt -f "${BASE_DIR}/globals-params.yml" -f "${BASE_DIR}/values.yml" \
  --ignore-unknown-comments --data-values-env YTT > "${ENV_PIPELINE_DIR}/pipelines/globals.yml"

PRODUCTS=$(yq r "${BASE_DIR}/values.yml" products -j | jq -r '.[] | select(.deploy_product==true) | .name')

for p in ${PRODUCTS}; do
  echo "------ ${p} ------"
  if [[ ! -d "${ENV_PIPELINE_DIR}/config/${p}" ]]; then
    mkdir -p "${ENV_PIPELINE_DIR}/config/${p}" && touch "${ENV_PIPELINE_DIR}/config/${p}/.gitkeep"
  fi

  if [[ ! -d "${ENV_PIPELINE_DIR}/vars/${p}" ]]; then
    mkdir -p "${ENV_PIPELINE_DIR}/vars/${p}" && touch "${ENV_PIPELINE_DIR}/vars/${p}/.gitkeep"
  fi

  if [[ ! -d "${ENV_PIPELINE_DIR}/env" ]]; then
    mkdir -p "${ENV_PIPELINE_DIR}/env" && touch "${ENV_PIPELINE_DIR}/env/.gitkeep"
  fi
done;
