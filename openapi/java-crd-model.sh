#!/usr/bin/env bash

VERBOSE=false
PACKAGE_NAME=${PACKAGE_NAME:-io.kubernetes.client}
CLIENT_VERSION=${CLIENT_VERSION:-5.0-SNAPSHOT}
OUTPUT_DIR=${OUTPUT_DIR:-java}

print_usage() {
  echo "Usage: generate a java project using input openapi spec from stdin" >& 2
  echo " -c: CLIENT_VERSION, the version of the generated java project." >& 2
  echo " -p: PACKAGE_NAME, the base package name of the generated java project. " >& 2
  echo " -v: Verbose output." >& 2
}

while getopts 'c:p:v' flag; do
  case "${flag}" in
    c) CLIENT_VERSION="${OPTARG}" ;;
    #n) CRD_GROUP_NAME="${OPTARG}" ;;
    p) PACKAGE_NAME="${OPTARG}" ;;
    v) VERBOSE=true ;;
    *) print_usage
       exit 1 ;;
  esac
done

[[ $VERBOSE ]] && echo "CLIENT_VERSION: $CLIENT_VERSION" >& 2
[[ $VERBOSE ]] && echo "PACKAGE_NAME: $PACKAGE_NAME" >& 2
if [[ -z "$CRD_GROUP_NAME" ]]; then
  [[ $VERBOSE ]] && echo "CRD_GROUP_NAME not specified, won't prune the output directory after generation.." >& 2
else
  [[ $VERBOSE ]] && echo "CRD_GROUP_NAME: $CRD_GROUP_NAME" >& 2
fi

echo "" >& 2 # empty line


echo 'succesfully read openapi specs..' >&2

[[ -z $crd_group_name ]] && echo "filtering with crd group name: $crd_group_name" >& 2

[[ $verbose ]] && echo "ensuring output directory $OUTPUT_DIR exists.." >& 2

mkdir -p ${OUTPUT_DIR}

#

echo 'rendering settings file to /tmp/settings (inside container)' >& 2
read -d '' settings << EOF
export KUBERNETES_BRANCH="${KUBERNETES_BRANCH}"

export CLIENT_VERSION="${CLIENT_VERSION}"

export PACKAGE_NAME="${PACKAGE_NAME}"
EOF

echo ${settings} > /tmp/settings 

cat > ${OUTPUT_DIR}/swagger.json.unprocessed


CLIENT_VERSION="${CLIENT_VERSION}" \
PACKAGE_NAME="${PACKAGE_NAME}" \
CLEANUP_DIRS="${CLEANUP_DIRS:-}" \
KUBERNETES_BRANCH="${KUBERNETES_BRANCH:-release-1.14}" \
CLIENT_LANGUAGE="java" \
SWAGGER_CODEGEN_USER_ORG="${SWAGGER_CODEGEN_USER_ORG:-swagger-api}" \
SWAGGER_CODEGEN_COMMIT="${SWAGGER_CODEGEN_COMMIT:-v2.2.3}" \
OPENAPI_SKIP_FETCH_SPEC="${OPENAPI_SKIP_FETCH_SPEC:-true}" \
USERNAME="${USERNAME:-kubernetes}" \
REPOSITORY="${REPOSITORY:-kubernetes}" \
$(pwd)/generate_client_in_container.sh ${OUTPUT_DIR} 1>&2

rm ${OUTPUT_DIR}/swagger.json.unprocessed

tar -czf - ${OUTPUT_DIR}


