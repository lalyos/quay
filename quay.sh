#!/bin/bash

#set -eo pipefail

if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}


quay() {
    declare desc="Calls quay.io api"

    path=${1:? required api path };
    shift;
    [[ "$TRACE" ]] && set -x
    curl -s \
        -H "Content-type: application/json" \
        -H "Accept: application/json" \
        -H "Authorization: Bearer $QUAY_TOKEN" \
        "https://quay.io/api/v1/${path#/}" "$@" \
        | jq .
    set +x
}

add_notification() {

    declare desc="Add webhook notification to repository"
    declare method=${1:? required notification method} repo=${2:?reuired full reponame} event=${3:? reuired eventname} config_json=${4:? required config_json}

    quay repository/${repo}/notification/ -d @- <<EOF
{
  "eventConfig": {},
  "title": "${event}",
  "event": "${event}",
  "config": ${config_json},
  "method": "${method}"
}
EOF
}

add_webhook_notif() {

    add_notification webhook hortonworks/cloudbreak  build_success '{"url": "'$RUNSCOPE_URL'/build-success"}'
}

add_hipchat_notif() {

    declare repo=${1:? reuired quay repo fullname}
    for event in build_failure build_success; do
        debug "add hipchat notification for ${event} on repo: ${repo}"
        add_notification hipchat ${repo} ${event} '{"room_id": "'$HIPCHAT_ROOM_ID'","notification_token": "'$HIPCHAT_ROOM_TOKEN'"}'
    done

}

main() {
  : ${DEBUG:=1}
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || true
