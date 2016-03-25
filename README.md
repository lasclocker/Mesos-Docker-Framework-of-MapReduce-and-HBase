# Mesos-Docker-Framework-of-MapReduce-and-HBase
This project is to introduce how to use mesos to start docker container, and manage the use of resources. Since mesos can simultaneously support multiple computing frameworks, we installed Hadoop and Hbase in the docker image in advance. We use mesos to start the docker container, and use docker to start the frameworks of MapReduce and HBase.

## Compile the project
1. use `mvn package` to recompile the project.  
## Run the project
1. before run the project, use `./check-privateHub-all-service.sh` to check the run enviroment.  
2. use `./start-framework.sh MapReduce` to start the framework of MapReduce.  
3. use `./start-framework.sh HBase` to start the framework of HBase.  
4. when the framework has been started, you should attach to the docker image of MapReduce and HBase, and use `./start-yarn.sh` to start yarn.
