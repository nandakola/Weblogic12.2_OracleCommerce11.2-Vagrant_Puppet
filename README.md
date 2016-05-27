## weblogic-12.2.1 Oracle commerce 11.1 - Vagrant-puppet

The puppet 4.2 reference implementation of https://github.com/biemond/biemond-orawls

Should work for VMware and Virtualbox

### Details
- CentOS 7.0 Vagrant box
- Puppet 4.2.2
- Vagrant >= 1.8.0
- Oracle Virtualbox >= 4.3.20 (tested on 4.3.38 try to use the same version)
- VMware fusion >= 6 (Not tested)

creates a 12.2.1 WebLogic cluster ( admin, store, bcc )

Add the all the Oracle binaries to /software (I have mapped it to D:/Clients/mFleet/software on my local)

If you want to change the location edit Vagrantfile and update the software share
- admin.vm.synced_folder "software", "/software"
- node1.vm.synced_folder "software", "/software"
- node2.vm.synced_folder "software", "/software"

We can use this folder for codebase also.

### Software
- Weblogic 12.2.1 [fmw_12.2.1.0.0_wls.jar](http://www.oracle.com/technetwork/middleware/fusion-middleware/downloads/index.html)
- JDK 8 [jdk-8u72-linux-x64.tar.gz](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
- JCE Policy 8 [jce_policy-8.zip](http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html)
- Oracle Commerce 11.1 [OCPlatform11.2.bin]
- [Download Software](https://www.dropbox.com/sh/hsirxpqkx8juav4/AABrDaA5QJ30cnVohGvCEfgBa?dl=0)

### Set up

- vagrant up

It will take some time .. Once all the boxes are up, do a halt on all the boxes and restart them before you use them

- vagrant halt
- vagrant up

Once done..
ssh to the admin box

- vagrant ssh admin

Start admin server first.
```
- su oracle (su as oracle/oracle)
- cd /opt/oracle/middleware12c/
- ./startWebLogic.sh
```

ssh to store box

- vagrant ssh store

Start "store" as managed server (it will prompt for username and password , provide weblogic/weblogic1)
```
- su oracle (su as oracle/oracle)
- cd /opt/oracle/middleware12c/bin
- ./startManagedWebLogic.sh "wlsServer1" "http://10.10.10.10:7001"
```

ssh to bcc box

- vagrant ssh bcc

Start "bcc" as managed server (it will prompt for username and password , provide weblogic/weblogic1)
```
- su oracle (su as oracle/oracle)
- cd /opt/oracle/middleware12c/bin
- ./startManagedWebLogic.sh "wlsServer2" "http://10.10.10.10:7001"
```

Make sure admin server is up when you are starting "store" and "bcc" for the first time.
(once its done you can start store and bcc as standalone servers with out starting admin server)

atg location
```
/opt/oracle/middleware12c/atg/ATG11.1
```
weblogic location
```
/opt/oracle/middleware12c
```

### Startup the individual images

- vagrant up admin
- vagrant up store
- vagrant up bcc

### Application Access

- http://10.10.10.100:7001/console (weblogic/weblogic1)
- http://10.10.10.200:8001/store (future store)
- http://10.10.10.200:8001/atg/bcc (future bcc)

Access weblogic console and check the servers tab and datasource tab to verify the install.
Server tab should be listed with 3 servers (admin,wlsServer1 and wlsServer2)
Datasource tab should have the DS listed below.

### Datasources

- Right now 4 data sources are configured for store and bcc
    - ATGCoreDS
    - ATGCataDS
    - ATGCatbDS
    - ATGCaDS

All the above datasources are configured to oracle running on localhost
To modify them update the datasource properties in hierdata/admin.example.com
```
"datasource_instances:" (line 562)

```
