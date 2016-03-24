/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.codefutures.tutorial.mesos.docker;


import org.apache.mesos.Protos;
import org.apache.mesos.Scheduler;
import org.apache.mesos.SchedulerDriver;
import org.apache.mesos.Protos.Volume;
import org.apache.mesos.Protos.Volume.Mode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;


/** Example scheduler to launch Docker containers. */
public class ExampleScheduler implements Scheduler {

  /** Logger. */
  private static final Logger logger = LoggerFactory.getLogger(ExampleScheduler.class);

  /** Docker image name. */
  private final String imageName;

  /** Number of instances to run. */
  private int desiredInstances;
  
  
  /** some parameters in mesos-docker-framework.xml. */
  private final String frameworkNameString;
  private final String mesos_slaves_ip;
  private final String[] hadoop_master_publish_ports;
  private final double each_docker_container_cpus;
  private final double each_docker_container_mem;
  private final String start_mesos_docker_hadoop_shell_script;
  private String mount_directory_on_host = "";
  private String mount_directory_on_container = ""; 
  private String resourceManagerHostName = "";
  private int set_refuse_seconds = 0;
  
  
  /** store hadoop nodes's host name */
  private String[] d_hostName = null;
  
  /** index for assignment */
  private int index = 0;
  
  private String hostname = "";
  
  /** define hadoop nodes' hosts name. */
  private boolean has_hostName = false;
  
  
  /** hadoop nodes' network configure. */
  private boolean has_networkConfigure = false;
  
  private boolean isMasterStart = false;
  
  
  /** mesos slaves host names. */
  private List<String> newSlavesArray = new ArrayList<String>();
  
  /** mesos slaves hosts nums. */
  private int mesos_slaves_ip_len = 0;
  
  private String lineMasterIp = "";

  /** List of pending instances. */
  private final List<String> pendingInstances = new ArrayList<>();

  /** List of running instances. */
  private final List<String> runningInstances = new ArrayList<>();

  /** Task ID generator. */
  private final AtomicInteger taskIDGenerator = new AtomicInteger();
  
  public List<String> getLines(String filename) {
      LineNumberReader reader = null;
      List<String> slavesArray = new ArrayList<String>();
      String lineRead = "";
      try {
          reader = new LineNumberReader(new FileReader(filename));
          while ((lineRead = reader.readLine()) != null) {
        	  slavesArray.add(lineRead);
          }
      } catch (Exception ex) {
          ex.printStackTrace();
      } finally {
          try {
              reader.close();
          } catch (Exception ex) {
              ex.printStackTrace();
          }
      }
      return slavesArray;
  }


  /** Constructor. */
  public ExampleScheduler(String frameworkNameString, String imageName, String mesos_slaves_ip, String[] hadoop_master_publish_ports,
		  double each_docker_container_cpus, double each_docker_container_mem,
		  String start_mesos_docker_hadoop_shell_script, 
		  String mount_directory_on_host, String mount_directory_on_container,
		  int set_refuse_seconds, String resourceManagerHostName) {
	this.frameworkNameString = frameworkNameString;
    this.imageName = imageName;
    this.mesos_slaves_ip = mesos_slaves_ip;
    this.hadoop_master_publish_ports = hadoop_master_publish_ports;
    this.each_docker_container_cpus = each_docker_container_cpus;
    this.each_docker_container_mem = each_docker_container_mem;
    this.start_mesos_docker_hadoop_shell_script = start_mesos_docker_hadoop_shell_script;
    this.mount_directory_on_host = mount_directory_on_host;
    this.mount_directory_on_container = mount_directory_on_container;
    this.set_refuse_seconds = set_refuse_seconds;
    this.resourceManagerHostName = resourceManagerHostName;
  }

  @Override
  public void registered(SchedulerDriver schedulerDriver, Protos.FrameworkID frameworkID, Protos.MasterInfo masterInfo) {
	List<Integer> masterIpPort = new ArrayList<>();
	masterIpPort.add(masterInfo.getIp());
	masterIpPort.add(masterInfo.getPort());
    logger.info("registered() master={}:{}, framework={}", masterIpPort, frameworkID);
  }

  @Override
  public void reregistered(SchedulerDriver schedulerDriver, Protos.MasterInfo masterInfo) {
    logger.info("reregistered()");
  }
  
  /**启动Hadoop集群 .*/
  public synchronized void startHadoop() {
	    if (has_networkConfigure) {
	  		String[] cmd = new String[4 + mesos_slaves_ip_len];  // 6 maybe change with cmd nums.!
	  		cmd[0] = "./" + start_mesos_docker_hadoop_shell_script;
	  		cmd[1] = imageName;
	  		cmd[2] = mount_directory_on_host;
	  		cmd[3] = mount_directory_on_container;
	  		for (int i = 0; i < mesos_slaves_ip_len; i++) {
				cmd[i + 4] = newSlavesArray.get(i);
			}
		    try {
		        Process process = Runtime.getRuntime().exec(cmd);
		        
		        /*
		         * 标准输出流
		         */
		        InputStreamReader ir = new InputStreamReader(process.getInputStream());
		        LineNumberReader input = new LineNumberReader(ir);
		        String line;
		        while((line = input.readLine()) != null) {
		        	System.out.println("@@@ Configure " + frameworkNameString + " : " + line);
		        	String[] lineArray = line.split(" ");
		        	if (lineArray.length == 2 && lineArray[1].equals("master")) {
		        		lineMasterIp = lineArray[0];
		        	}
		        }
		        input.close();
		        ir.close();
		        /*
		         * 标准错误流
		         */
		        InputStreamReader ie = new InputStreamReader(process.getErrorStream());
		        LineNumberReader inerror = new LineNumberReader(ie);
		        while((line = inerror.readLine()) != null) {
		        	System.out.println("@@@ error " + frameworkNameString + " : " + line);
		        }
		        inerror.close();
		        ie.close();
		    } catch (IOException e) {
		        // TODO: handle exception
		        e.printStackTrace();
		    }
		    has_networkConfigure = false;
		    logger.info("\nconfigure successfully ...");
	    }
  }
  
  /**构造Hadoop每个node的主机名 .*/
  public synchronized void  initializeHosts() {
	  if (! has_hostName) {
		    newSlavesArray = getLines(mesos_slaves_ip);
		    mesos_slaves_ip_len = newSlavesArray.size();
		    desiredInstances = mesos_slaves_ip_len;
		    d_hostName = new  String[desiredInstances];
		    for (int i = 0; i < d_hostName.length - 1; i++) {  // deal with master specially
				d_hostName[i] = "slave" + i;  
			}
		    has_hostName = true;
	    }
  }

  @Override
  public void resourceOffers(SchedulerDriver schedulerDriver, List<Protos.Offer> offers) {
    logger.info("resourceOffers() with {} offers", offers.size()); 
    
    if (lineMasterIp != "") {
    	System.out.println("masterNode ip is : " + lineMasterIp); // print master node of docker containers ip
	}
    
    initializeHosts();
    
    for(Protos.Offer offer : offers) {
    	
      String slaveHostName = offer.getHostname();
      /**过滤掉不需要启动的主机资源 .*/
      if (! newSlavesArray.contains(slaveHostName)) {
    	  Protos.Filters filters = Protos.Filters.newBuilder().setRefuseSeconds(set_refuse_seconds).build();
          schedulerDriver.declineOffer(offer.getId(), filters);
    	  continue;
	   }
	  
      List<Protos.TaskInfo> tasks = new ArrayList<>();
      List<Protos.OfferID> OfferList = new ArrayList<>();
      if (runningInstances.size() + pendingInstances.size() < desiredInstances) {
    	  
    	  /** 固定Hadoop的ResourceManger(即master节点)，即mapreduce的master节点为在mesos-docker-framework.xml指定的主机名 .*/
		  if (! isMasterStart && slaveHostName.equals(resourceManagerHostName)) {
	    	  hostname = "master";
	          isMasterStart = true;
	       } else {
	    	  hostname = d_hostName[index];
	    	  index ++;
	          System.out.println("---- slave index : " + index);
	       }

	        // generate a unique task ID
	        Protos.TaskID taskId = Protos.TaskID.newBuilder()
	            .setValue(Integer.toString(taskIDGenerator.incrementAndGet())).build();
	
	        logger.info("Launching task {}", taskId.getValue());
	        pendingInstances.add(taskId.getValue());
	
	        // docker image info
	        Protos.ContainerInfo.DockerInfo.Builder dockerInfoBuilder = Protos.ContainerInfo.DockerInfo.newBuilder();
	        dockerInfoBuilder.setImage(imageName);
	        dockerInfoBuilder.setNetwork(Protos.ContainerInfo.DockerInfo.Network.NONE);  //change BRIDGE to NONE
	        
	        
	        /** addParameters()方法可以实现Docker CLI的run参数 .*/
	        if (hostname == "master") {
	        	 for (int i = 0; i < hadoop_master_publish_ports.length; i++) {
	        		 dockerInfoBuilder.addParameters(Protos.Parameter.newBuilder().setKey("publish").setValue(hadoop_master_publish_ports[i]).build());
				 }
			}
	        dockerInfoBuilder.addParameters(Protos.Parameter.newBuilder().setKey("tty").setValue("true").build());
	        dockerInfoBuilder.addParameters(Protos.Parameter.newBuilder().setKey("interactive").setValue("true").build());
	        dockerInfoBuilder.addParameters(Protos.Parameter.newBuilder().setKey("privileged").setValue("true").build());        
	        dockerInfoBuilder.addParameters(Protos.Parameter.newBuilder().setKey("hostname").setValue(hostname).build());
	        
	        /** 添加启动container时的mount目录 .*/
	        Volume.Builder volumeBuilder = Volume.newBuilder()
	        		.setContainerPath(mount_directory_on_container)
	        		.setHostPath(mount_directory_on_host)
	        		.setMode(Mode.RW);
	
	        
	         //container info
	        Protos.ContainerInfo.Builder containerInfoBuilder = Protos.ContainerInfo.newBuilder();
	        containerInfoBuilder.setType(Protos.ContainerInfo.Type.DOCKER);
	        containerInfoBuilder.setDocker(dockerInfoBuilder.build());
	        containerInfoBuilder.addVolumes(volumeBuilder.build());  //setMountDirectory
	        
	        // create task to run
	        Protos.TaskInfo task = Protos.TaskInfo.newBuilder()
	        	.setName(frameworkNameString + "-" + hostname)
	            .setTaskId(taskId)
	            .setSlaveId(offer.getSlaveId())
	            .addResources(Protos.Resource.newBuilder()
	                .setName("cpus")
	                .setType(Protos.Value.Type.SCALAR)
	                .setScalar(Protos.Value.Scalar.newBuilder().setValue(each_docker_container_cpus)))
	            .addResources(Protos.Resource.newBuilder()
	                .setName("mem")
	                .setType(Protos.Value.Type.SCALAR)
	                .setScalar(Protos.Value.Scalar.newBuilder().setValue(each_docker_container_mem)))
	//             .addResources(Protos.Resource.newBuilder()
	//                     .setName("disk")
	//                     .setType(Protos.Value.Type.SCALAR)
	//                     .setScalar(Protos.Value.Scalar.newBuilder().setValue(each_docker_container_mem)))
	//             .addResources(Protos.Resource.newBuilder()
	//                     .setName("ports")
	//                     .setType(Protos.Value.Type.SCALAR)
	//                     .setScalar(Protos.Value.Scalar.newBuilder().setValue(each_docker_container_mem)))
	            .setContainer(containerInfoBuilder)
	            .setCommand(Protos.CommandInfo.newBuilder().setShell(false))
	            .build();
	
	        tasks.add(task);
      }
      OfferList.add(offer.getId());
      Protos.Filters filters = Protos.Filters.newBuilder().setRefuseSeconds(1).build();
      schedulerDriver.launchTasks(OfferList, tasks, filters);
    }
    startHadoop(); // 启动Hadoop
  }

  @Override
  public void offerRescinded(SchedulerDriver schedulerDriver, Protos.OfferID offerID) {
    logger.info("offerRescinded()");
  }

  @Override
  public void statusUpdate(SchedulerDriver driver, Protos.TaskStatus taskStatus) {

    final String taskId = taskStatus.getTaskId().getValue();
    
    logger.info("statusUpdate() task {} is in state {}",
        taskId, taskStatus.getState());

    switch (taskStatus.getState()) {
      case TASK_RUNNING:
        pendingInstances.remove(taskId);
        runningInstances.add(taskId);
        System.out.println(taskStatus.getMessage());
        break;
      case TASK_FAILED:
    	System.out.println(taskStatus.getMessage());   // print failed info.
      case TASK_ERROR:
          System.out.println(taskStatus.getMessage());  // print error info.
          break;
      case TASK_FINISHED:
    	System.out.println(taskStatus.getMessage());
        pendingInstances.remove(taskId);
        runningInstances.remove(taskId);
        break;
      default:
		break;
    }

    logger.info("Number of instances: pending={}, running={}",
        pendingInstances.size(), runningInstances.size());
    
    if (pendingInstances.size() == 0 && runningInstances.size() == desiredInstances) {
    	System.out.println("->->->-> start configure Hadoop...");
    	has_networkConfigure = true;
	}
  }

  @Override
  public void frameworkMessage(SchedulerDriver schedulerDriver, Protos.ExecutorID executorID, Protos.SlaveID slaveID, byte[] bytes) {
    logger.info("frameworkMessage()");
  }

  @Override
  public void disconnected(SchedulerDriver schedulerDriver) {
    logger.info("disconnected()");
  }

  @Override
  public void slaveLost(SchedulerDriver schedulerDriver, Protos.SlaveID slaveID) {
    logger.info("slaveLost()");
  }

  @Override
  public void executorLost(SchedulerDriver schedulerDriver, Protos.ExecutorID executorID, Protos.SlaveID slaveID, int i) {
    logger.info("executorLost()");
  }

  @Override
  public void error(SchedulerDriver schedulerDriver, String s) {
    logger.error("error() {}", s);
  }

}
