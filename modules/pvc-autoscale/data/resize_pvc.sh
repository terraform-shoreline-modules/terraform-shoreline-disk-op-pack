#!/bin/bash

if [ -z "$ALARM_POD_NAME" ] || [ -z "$ALARM_NAMESPACE" ]; then
    printf -- "Executing as interactive action, action Usage: action <action-name> = resize-pvc.sh POD_NAME POD_NAMESPACE"
    POD_NAME=$1
    POD_NAMESPACE=$2
else 
    POD_NAME=${ALARM_POD_NAME}
    POD_NAMESPACE=${ALARM_NAMESPACE}
fi

PVC_REGEX=${PVC_REGEX}
PVC_INCREMENT=${PVC_INCREMENT}
PVC_MAX_SIZE=${PVC_MAX_SIZE}
MAX_STATUS_CHECKS=10                # max number of times to check pvc patch status
STATUS_CHECK_WAIT_SEC=5             # amount of time in seconds to wait between pvc patch status checks


if [ -z "$PVC_REGEX" ] || [ -z "$POD_NAMESPACE" ] || [ -z "$POD_NAME" ] || [ -z "$PVC_INCREMENT" ] || [ -z "$PVC_MAX_SIZE" ]; 
then
    printf -- "Required params for resize_pvc action are POD_NAME, POD_NAMESPACE, PVC_REGEX, PVC_INCREMENT, PVC_MAX_SIZE\n"
    exit 127
fi

echo "Executing kubectl command with POD_NAME=${POD_NAME} NAMESPACE=${POD_NAMESPACE} PVC_REGEX=${PVC_REGEX}\n"

PVC_LIST=`kubectl get pods $POD_NAME -n $POD_NAMESPACE -o json | jq --arg PVC_REGEX $PVC_REGEX  -c '.spec.volumes | .[] | select(has("persistentVolumeClaim")) | select(.persistentVolumeClaim.claimName|test($PVC_REGEX)) | .persistentVolumeClaim.claimName'`
if [ -z "$PVC_LIST" ]; 
then
    printf -- "PVC_LIST for $PVC_REGEX is empty, exiting"
    exit 127
fi

printf -- "The selected PVC's are:\n"
echo "${PVC_LIST}"
printf -- "\n"



for PVC in "${PVC_LIST}"
do
    PVC=${PVC:1:-1} # Strip quotes from pvc name
    echo "pvc name:$PVC"
    PVC_SIZE=`kubectl get pvc -n $POD_NAMESPACE $PVC -o json | jq -c '.status.capacity.storage'`
    PVC_UNIT=${PVC_SIZE: -3:-1} # Retrieve unit from pvc size
    echo "pvc units: $PVC_UNIT"
    PVC_SIZE=${PVC_SIZE:1:-3} # Retrive size without unit from pvc size
    echo "old pvc size for $PVC: $PVC_SIZE$PVC_UNIT"
    let NEW_PVC_SIZE=$PVC_SIZE+$PVC_INCREMENT
    if [ $NEW_PVC_SIZE -gt $PVC_MAX_SIZE ]
    then
        echo new pvc size "("$PVC_SIZE$PVC_UNIT")" is greater than max pvc size "("$PVC_MAX_SIZE$PVC_UNIT")". exiting script without patch attempt.
        exit 1
    fi
    echo "new calculated pvc size for $PVC: $NEW_PVC_SIZE$PVC_UNIT"
    PATCH_JSON=$(echo '{"spec":{"resources":{"requests":{"storage":"'$NEW_PVC_SIZE$PVC_UNIT'"}}}}')
    echo "attempting to patch $PVC with json: $PATCH_JSON"
    kubectl patch pvc $PVC -n $POD_NAMESPACE -p $PATCH_JSON
    for (( i=1; i<=$MAX_STATUS_CHECKS; i++ ))
    do
        echo "checking patch status, number of attempts $i"
        LATEST_STATUS=$(kubectl get events -n $POD_NAMESPACE -o json | jq --arg POD_NAMESPACE $POD_NAMESPACE --arg PVC $PVC -c '[.items | .[] | select(.involvedObject.name==$PVC and .involvedObject.namespace==$POD_NAMESPACE and .involvedObject.kind=="PersistentVolumeClaim")] | last | {type: .type, reason: .reason, message: .message}')
        STATUS_TYPE=`echo $LATEST_STATUS | jq -c '.type'`
        echo "STATUS_TYPE=$STATUS_TYPE"
        STATUS_REASON=`echo $LATEST_STATUS | jq -c '.reason'`
        echo "STATUS_REASON=$STATUS_REASON"
        if [[ ( $STATUS_TYPE == "\"Normal\"" ) && ( $STATUS_REASON == "\"ProvisioningSucceeded\""  ||  $STATUS_REASON == "\"FileSystemResizeSuccessful\"" ) ]];
        then
            echo "update pvc patch succeeded for pvc=$PVC with new size=$NEW_PVC_SIZE$PVC_UNIT"
            exit 0
        else
            echo "update pvc patch still in progress"
        fi
        `sleep $STATUS_CHECK_WAIT_SEC`
    done
    echo "reached maximum patch status check limit."
done
exit 0
