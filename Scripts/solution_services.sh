#!/bin/bash
#Baseado no script https://github.com/FIWARE/tutorials.Getting-Started/blob/master/services

source .env

set -e

if (( $# != 1 )); then
	echo "Número de parâmetros inválido "
	echo "Utilização: services [create|start|stop]"
	exit 1
fi

waitForMongo () {
	echo -e "\n⏳ Waiting for \033[1mMongoDB\033[0m to be available\n"
	while ! [ `docker inspect --format='{{.State.Health.Status}}' db-mongo` == "healthy" ]
	do 
		sleep 1
	done
}

waitForOrion () {
	echo -e "\n⏳ Waiting for \033[1;34mOrion\033[0m to be available\n"

	while ! [ `docker inspect --format='{{.State.Health.Status}}' fiware-orion` == "healthy" ]
	do
	  echo -e "Context Broker HTTP state: " `curl -s -o /dev/null -w %{http_code} 'http://localhost:1026/version'` " (waiting for 200)"
	  sleep 1
	done
}

waitForMySQL () {
	echo -e "\n⏳ Waiting for \033[1mMySQL\033[0m to be available\n"
	while ! [ `docker inspect --format='{{.State.Health.Status}}' db-mysql` == "healthy" ]
	do 
		sleep 1
	done
}

displayServices () {
	echo ""
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter name=fiware-*
	echo ""
}

stoppingContainers () {
	echo "Stopping containers"
	docker-compose -f docker_compose_1Fase.yml --log-level ERROR -p fiware down -v --remove-orphans
	docker-compose -f docker_compose_2Fase.yml --log-level ERROR -p fiware down -v --remove-orphans
}



command="$1"
case "${command}" in
	"help")
		echo "Utilização: services [create|start|stop]"
		;;
	"start")
		stoppingContainers
		#echo -e "Starting two containers \033[1;34mOrion\033[0m and a \033[1mMongoDB\033[0m database."
		#echo -e "- \033[1;34mOrion\033[0m is the context broker"
		#echo ""
		docker-compose -f docker_compose_1Fase.yml --log-level ERROR -p fiware up -d --remove-orphans
		waitForMySQL
		source register_cygnus_to_orion.sh
		source config_keyrock.sh
		source .pep_proxy_login
		
		docker-compose -f docker_compose_2Fase.yml --log-level ERROR -p fiware up -d 
		#docker-compose --log-level ERROR -p fiware up -d --remove-orphans
		displayServices
		;;
	"stop")
		stoppingContainers
		;;
	"create")
		echo "Obter imagem MongoDB"
		docker pull mongo:$MONGO_DB_VERSION
		echo "Obter imagem FIWARE Orion Context Broker"
		docker pull fiware/orion:$ORION_VERSION

		echo "Obter imagem FIWARE IoT Agent"
		docker pull fiware/iotagent-lorawan:$IOTA_VERSION

		echo "Obter imagem FIWARE Cygnus-NGSI"
		docker pull fiware/cygnus-ngsi:$CYGNUS_VERSION

		echo "Obter imagem FIWARE STH Comet"
		docker pull fiware/sth-comet:$STH_COMET_VERSION

		echo "Obter imagem FIWARE KeyRock Identity Manager"
		docker pull fiware/idm:$KEYROCK_VERSION

		echo "Obter imagem MySQL DB"
		docker pull mysql:$MYSQL_DB_VERSION

		echo "Obter imagem FIWARE Wilma PEP-Proxy"
		docker pull fiware/pep-proxy:$WILMA_VERSION
		
		echo "Obter imagem FIWARE Wilma PEP-Proxy"
		docker pull ivomiguel/management-api:latest
		;;
	*)
		echo "Command not Found."
		echo "usage: services [create|start|stop]"
		exit 127;
		;;
esac
