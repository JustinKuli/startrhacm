#! /bin/bash

set -e

CLUSTERPOOL_MIN=${CLUSTERPOOL_MIN:-1}

echo "Using exports (if there's no output, please set these variables and try again):"
echo "* SERVICE_ACCOUNT_NAME: ${SERVICE_ACCOUNT_NAME}"
echo "* CLUSTERPOOL_TARGET_NAMESPACE: ${CLUSTERPOOL_TARGET_NAMESPACE}"
echo "* CLUSTERPOOL_MIN: ${CLUSTERPOOL_MIN}"

cat >clusterpool-shrink.yaml <<EOF
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: clusterpool-shrink
spec:
#            ┌────────────── minute (0 - 59)
#            │ ┌────────────── hour (0 - 23) (Time in UTC)
#            │ │ ┌───────────── day of the month (1 - 31)
#            │ │ │ ┌───────────── month (1 - 12)
#            │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
#            │ │ │ │ │
  schedule: "* 1 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ${SERVICE_ACCOUNT_NAME}
          containers:
          - name: clusterpool-shrink
            image: bitnami/kubectl:latest
            imagePullPolicy: IfNotPresent
            command: 
            - /bin/sh
            args:
            - -c
            - date; for pool in \$(kubectl get clusterpool -n ${CLUSTERPOOL_TARGET_NAMESPACE} -o name); do kubectl patch \${pool} -n ${CLUSTERPOOL_TARGET_NAMESPACE} --type merge --patch '{"spec":{"size":"${CLUSTERPOOL_MIN}"}}'; done
          restartPolicy: OnFailure
EOF

echo ""
echo "CronJob YAML created!"
echo "* To apply to the ClusterPool cluster:"
echo "oc apply -n ${CLUSTERPOOL_TARGET_NAMESPACE} -f clusterpool-shrink.yaml"
