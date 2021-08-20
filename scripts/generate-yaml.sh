#!/bin/bash
PLATFORM="google"
CLUSTER_TYPE="gke"
FLOW_STORAGE_PROTOCOL="gcsfs"
MAX_WORKERS="10"

REGION=$TF_VAR_region
STORAGE_PLATFORM=$PLATFORM
STORAGE_REGION=$REGION
STORAGE_TARGET_NAME=$FLOW_CACHE_CONTAINER
FLOW_STORAGE=$FLOW_STORAGE_CONTAINER
PANGEO_FORGE_VERSION=$(echo $BAKERY_IMAGE | sed -rn "s/.*pangeoforgerecipes-(.*)/\1/p")
PREFECT_VERSION=$(echo $BAKERY_IMAGE | sed -rn "s/.*prefect-(.*)_pangeoforgerecipes.*/\1/p")
PANGEO_NOTEBOOK_VERSION=$(echo $BAKERY_IMAGE | sed -rn "s/.*pangeonotebook-(.*)_prefect.*/\1/p")
WORKER_IMAGE=$BAKERY_IMAGE

function cleanup {
  echo "Removing temporary JSON file"
  rm -f /tmp/input.json
}

trap cleanup EXIT

cat > /tmp/input.json << EOF
{
  "devseed.bakery.development.$PLATFORM.$REGION":{
    "region":"$PLATFORM.$REGION",
    "targets": {
      "$STORAGE_TARGET_NAME":{
        "region":"$STORAGE_PLATFORM.$STORAGE_REGION",
        "description":"Flow output container",
        "private": {
          "protocol":"$FLOW_STORAGE_PROTOCOL"
        }
      }
    },
    "cluster": {
      "type":"$PLATFORM.$CLUSTER_TYPE",
      "pangeo_forge_version":"$PANGEO_FORGE_VERSION",
      "pangeo_notebook_version":"$PANGEO_NOTEBOOK_VERSION",
      "prefect_version":"$PREFECT_VERSION",
      "worker_image":"$WORKER_IMAGE",
      "flow_storage":"$FLOW_STORAGE",
      "flow_storage_protocol":"$FLOW_STORAGE_PROTOCOL",
      "max_workers":$MAX_WORKERS
    }
  }
}
EOF
python3 -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False, sort_keys=False)' < /tmp/input.json > bakery.yaml