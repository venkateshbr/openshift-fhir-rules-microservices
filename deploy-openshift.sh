SERVICE_GIT_URL=https://github.com/Vizuri/openshift-fhir-rules-microservices.git
RULES_GIT_URL=https://github.com/Vizuri/openshift-fhir-rules-rules.git
PROJECT=fhir-development

oc new-project $PROJECT

oc create -f openshift/templates/decisionserver64-is.json 

oc new-app --template=mongodb-persistent --param=DATABASE_SERVICE_NAME=fhirdb --param=MONGODB_USER=fhir --param=MONGODB_DATABASE=fhir

oc new-app --docker-image=sonatype/nexus3 --name=nexus

STATUS=`oc get dc nexus | tail -n +2 | awk '{print $4}'`
N=0
until [ $STATUS -gt 0 ]
do
   N=$[$N+1]
   echo "Waiting for nexus to start $N. Retrying ..."
   if [ $N -ge 20 ] ; then
      echo "Nexus is not started, Check your OpenShift Configuration"
      break;
   fi
   sleep 10s;
   STATUS=`oc get dc nexus | tail -n +2 | awk '{print $4}'`
done

oc new-app  --file=openshift/templates/maven-pipeline.yaml -p APP_NAME=fhir-parent -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-parent

oc new-app --file=openshift/templates/maven-pipeline.yaml -p APP_NAME=fhir-base -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-base

oc new-app --file=openshift/templates/docker-container-pipeline.yaml -p APP_NAME=fhir-base-container -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-base-container

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-patient-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-patient-service

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-observation-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-observation-service

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-riskassessment-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-riskassessment-service

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-questionnaire-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-questionnaire-service

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-questionnaireresponse-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-questionnaireresponse-service

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-familymemberhistory-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-familymemberhistory-service

oc new-app --file=openshift/templates/springboot-pipeline.yaml -p APP_NAME=fhir-risk-assessment-bulk-service -p GIT_SOURCE_URL=${SERVICE_GIT_URL} -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-risk-assessment-bulk-service

oc new-app -f openshift/templates/decisionserver64-pipeline.yaml -p KIE_CONTAINER_DEPLOYMENT='fhir-framinghamRules=com.vizuri.fhir:fhir-framinghamRules:1.0-SNAPSHOT' -p KIE_SERVER_USER=kieserver -p KIE_SERVER_PASSWORD=kieserver1!  -p APPLICATION_NAME=framingham -p SOURCE_REPOSITORY_URL=${RULES_GIT_URL} -p SOURCE_REPOSITORY_REF=master -p CONTEXT_DIR=fhir-framinghamRules -p IMAGE_STREAM_NAMESPACE=$PROJECT -e CONTAINER_HEAP_PERCENT=.75

oc new-app -f openshift/templates/decisionserver64-pipeline.yaml -p KIE_CONTAINER_DEPLOYMENT='fhir-heartdisease-rules=com.vizuri.fhir:fhir-heartdisease-rules:1.0-SNAPSHOT' -p KIE_SERVER_USER=kieserver -p KIE_SERVER_PASSWORD=kieserver1!  -p APPLICATION_NAME=heart-rules -p SOURCE_REPOSITORY_URL=${RULES_GIT_URL} -p SOURCE_REPOSITORY_REF=master -p CONTEXT_DIR=fhir-heartdisease -p IMAGE_STREAM_NAMESPACE=$PROJECT -e CONTAINER_HEAP_PERCENT=.75

oc new-app -f openshift/templates/decisionserver64-pipeline.yaml -p KIE_CONTAINER_DEPLOYMENT='fhir-diabetes=com.vizuri.fhir:fhir-diabetes:1.0-SNAPSHOT' -p KIE_SERVER_USER=kieserver -p KIE_SERVER_PASSWORD=kieserver1!  -p APPLICATION_NAME=diabetes-rules -p SOURCE_REPOSITORY_URL=${RULES_GIT_URL} -p SOURCE_REPOSITORY_REF=master -p CONTEXT_DIR=fhir-diabetes -p IMAGE_STREAM_NAMESPACE=$PROJECT -e CONTAINER_HEAP_PERCENT=.75

oc new-app -f openshift/templates/nodejs-pipeline.yaml -p APP_NAME=fhir-frontend -p GIT_SOURCE_URL=${SERVICE_GIT_URL}  -p GIT_SOURCE_REF=master -p CONTEXT_DIR=fhir-frontend

oc start-build -w fhir-parent
oc start-build -w fhir-base
oc start-build -w fhir-base-container
oc start-build fhir-patient-service
oc start-build fhir-observation-service
oc start-build fhir-riskassessment-service
oc start-build fhir-questionnaire-service
oc start-build fhir-questionnaireresponse-service
oc start-build fhir-familymemberhistory-service
oc start-build fhir-risk-assessment-bulk-service
oc start-build framingham
oc start-build heart-rules
oc start-build diabetes-rules
oc start-build fhir-frontend


