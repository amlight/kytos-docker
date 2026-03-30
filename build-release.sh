#!/bin/bash

RELEASE="${1:-master}"

DOCKERFILE="releases/$RELEASE/Dockerfile"
test -f $DOCKERFILE || DOCKERFILE=Dockerfile

if [[ $RELEASE != "master" ]]; then
  for repo in $(grep ^ARG $DOCKERFILE |  awk -F "[ =]" '{print $2}' | cut -d_ -f2- | sed 's/python_openflow/python-openflow/; s/kytos_utils/kytos-utils/g'); do curl -s -L   -H "Accept: application/vnd.github+json"   https://api.github.com/repos/kytos-ng/$repo/releases > /tmp/repo-json-$repo; done

 ARGS=""
  for repo in $(grep ^ARG $DOCKERFILE |  awk -F "[ =]" '{print $2}' | cut -d_ -f2- | sed 's/python_openflow/python-openflow/; s/kytos_utils/kytos-utils/g'); do ARGS="$ARGS --build-arg branch_"$(echo $repo | tr '-' '_')=$(cat /tmp/repo-json-$repo | jq -r '.[].name' | grep $RELEASE | grep -E -v -- '-b[0-9]*$' | sort | tail -n1); done
  ARGS=$(echo $ARGS | sed "s#branch_ui=#release_ui=download/#g")

  rm -f /tmp/repo-json-*
fi


CMD="docker build -f $DOCKERFILE --no-cache -t amlight/kytos:$RELEASE $ARGS ."

bash -x -c "$CMD"
