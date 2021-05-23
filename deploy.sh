#!/usr/bin/env bash

ACTIVE_CENTER="centro-1"
PASSIVE_CENTER="centro-2"
BUILDER_DOMAIN="builder.localhost.com"

usage="

$(basename "$0") 
[--help] 
[--deploy-builder]
[--install-apibuilder-job]
[--deploy-apibuilder]
[--nfs-ip}
------------------------------
  For Deploying builder, lets make the next vars mixure:
		 >> sh deploy.sh --deploy-builder --nfs-ip 10.10.10.1
		 
  For Deploying api-builder, lets exec >> sh deploy.sh --deploy-apibuilder
  
  For Installing the pipeline and exec the job >> sh deploy.sh --install-apibuilder-job

  Where:
--help Shows the FAQs.
--deploy-apibuilder will execute api-builder installation on k8s cluster $ACTIVE_CENTER
		It is highligh a previously kubernets cluster must have to initiate
		the file within path opentrends-builder/assets/opentrend-kubeconfig must be replaced the parameters with the real values, there is an example 
		##SET Centro-1
		kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig set-cluster centro-1 --server=https://180.45.88.33:443 --certificate-authority=ca_CENTRO_1.crt --embed-certs=true 
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig set-credentials USR_CENTRO_1 --client-key=USR_CENTRO_1.key --client-certificate=USR_CENTRO_1.crt --embed-certs=true
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig set-context centro-1 --cluster=centro-1 --namespace=default --user=USR_CENTRO_1
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig use-context centro-1
        
        
		##SET Centro-2        
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig set-cluster centro-2 --server=https://192.168.1.15:443 --certificate-authority=ca_CENTRO_2.crt --embed-certs=true 
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig set-credentials USR_CENTRO_2 --client-key=USR_CENTRO_2.key --client-certificate=USR_CENTRO_2.crt --embed-certs=true
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig set-context centro-2 --cluster=centro-2 --namespace=default --user=USR_CENTRO_2
        kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig use-context centro-2
	
	
--deploy-builder will deploy 1 replica on $ACTIVE_CENTER and 0 on $PASSIVE_CENTER.

--install-apibuilder-job will deploy the api-builder pipeline, it's highly recommended awaiting for the builder in status running.
	its mandatory the bastion machine where the script is running on, java installation already running

--nfs-ip is the nfs ipaddress to bound pvc 
"
procesar_args () {
options=$(getopt --options  -h -l deploy-builder,deploy-apibuilder,install-apibuilder-job,nfs-ip:,help -- "$@")

[ $? -eq 0 ] || {

        echo "Incorrect option provided"

        echo "$usage"

        exit 1

    }
    
eval set -- "$options"

    while [ $# -gt 0 ]; do

        case "$1" in

	 --deploy-apibuilder) DEPLOY_API_BUILDER=true;;
     --deploy-builder) DEPLOY_BUILDER=true;;
	 --install-apibuilder-job) INSTALL_API_BUILDER_PIPELINE=true;;
	 --nfs-ip) shift; NFS_IP=($1);;
     -h |--help) echo "$usage"
	 
      exit
	 
     ;;
	 
      --)
	 
        
           shift

            break

            ;;

        esac

        shift

    done

}



procesar_args "$@"

if [ "$DEPLOY_BUILDER" = "true" ]; then
 
 echo "Deploying BUILDER on $ACTIVE_CENTER..."
 sleep 3
 export  MYVAR=$NFS_IP
 envsubst < ./opentrends-builder/k8s/jenkins-template.yaml > ./opentrends-builder/k8s/jenkins-template_exported.yaml
 kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig use-context $ACTIVE_CENTER
 kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-builder/k8s/jenkins-template_exported.yaml
 kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig scale deploy builder --replicas=1 -n buildercicd
 echo "Deploying BUILDER on $PASSIVE_CENTER..."
 sleep 2
 kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig  use-context $PASSIVE_CENTER
 kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig ./opentrends-builder/k8s/jenkins-template_exported.yaml
 kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig scale deploy builder --replicas=0 -n buildercicd
 echo "BUILDER Deployment finalized"
 sleep 3
 unset MYVAR
fi

if [ "$DEPLOY_API_BUILDER" = "true" ]; then
	echo "Deploying API_BUILDER on $ACTIVE_CENTER..."
	sleep 3
	kubectl config --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig use-context $ACTIVE_CENTER
	kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-api-builder/k8s/ns-template.yml 
	sleep 1
	kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-api-builder/k8s/api-builder-configmap.yml -n buildercicd
	sleep 1
	kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-api-builder/k8s/api-builder-logback-configmap.yml -n buildercicd
	sleep 1
	kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-api-builder/k8s/api-builder-svc.yml -n buildercicd
	sleep 1
	kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-api-builder/k8s/api-builder-deployment.yml -n buildercicd
	sleep 3
	kubectl --kubeconfig=./opentrends-builder/assets/opentrend-kubeconfig apply -f ./opentrends-api-builder/k8s/api-builder-ingress.yml -n buildercicd
	sleep 2
	echo "
	YOU can now access to the api-builder service through  http://api-builder.localhost.com/build/api/swagger-ui.html#/api-builder-controller
	
	For checking data persistence you can manage
	
	http://api-builder.localhost.com/build/h2-ui
	    url: jdbc:h2:mem:testdb
	    username: sa
		password: password
	"
	echo "DONE"
fi

if [ "$INSTALL_API_BUILDER_PIPELINE" = "true" ]; then
	echo "Installing API_BUILDER Pipeline..."
	sleep 2
	
	java -jar opentrends-builder/assets/jenkins-cli.jar -s http://admin:admin@$BUILDER_DOMAIN/ create-job api-builder < opentrends-api-builder/assets/job-pipeline.xml
	echo "Executing Job against builder"
	sleep 1
	java -jar opentrends-builder/assets/jenkins-cli.jar -s http://admin:admin@$BUILDER_DOMAIN/  build api-builder -f -v -w
fi

