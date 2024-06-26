sudo apt-get update

pre-required:
#apt list | grep zlib -- search packages
#need these 3 
sudo apt-get install zlib1g-dev libreadline-dev gcc

#consists of all the necessary packages related to package building and compilation
sudo apt install build-essential

git clone https://github.com/theory/pgenv

#set the PATH environment variable to point to the executable directory
export PATH=$PATH:./pgenv/bin

pgenv

sudo chmod 777 pgenv

#install post if it not already install
sudo apt install postgresql postgresql-client postgresql-contrib

#Enable PostgreSQL at boot time by executing 
sudo update-rc.d postgresql enable

#Start the cluster immediately using the service
sudo service postgresql start

#install version 12.0 & 14.0 & 9.3.25
pgenv build 12.0

#list installed versions
pgenv versions

# which instance to start
pgenv use 12.0
pgenv stop


#many postgres installed or not, it is safe to use pg_ctlcluster
#pg_ctlcluster <version> <cluster> <action>
sudo pg_ctlcluster 12 main start
sudo pg_ctlcluster 12 main reload # reload config

pg_ctlcluster 12 main status # provide PGDATA -D & config path -c
pg_ctlcluster 12 main status -D /postgres/12


#STOP
sudo pg_ctlcluster stop -m smart # smart or fast or immediate 

#new install to set postgres user USE
sudo -i -u postgres

#set PGDATA
export PGDATA=/postgres/12

The PGDATA directory is structured in several files and subdirectories. The main files are as follows:
	postgresql.conf is the main configuration file, used as default when the service is started.
	postgresql.auto.conf is the automatically included configuration file used to store dynamically changed settings via SQL instructions.
	pg_hba.conf is the HBA file that provides the configuration regarding available database connections.
	PG_VERSION is a text file that contains the major version number (useful when inspecting the directory to understand which version of the cluster has managed the PGDATA directory).
	postmaster.pid is the PID of the running cluster.
	
inspect a PGDATA directory and extract mnemonic names: oid2name
The integer identifier is named OID (Object Identifier); this name is a historical term that today corresponds to the so-called filenode
"escaping" the PGDATA directory by means of tablespaces	

The maintenance processes are as follows:

>checkpointer is a process responsible for executing the checkpoints, which are points in time where the database ensures that all the data is actually stored persistently on the disk.
>background writer is responsible for helping to push the data out of the memory to permanent storage.
>walwriter is responsible for writing out the Write-Ahead Logs (WALs), the logs that are needed to ensure data reliability even in the case of a database crash.
>stats collector is a process that monitors the amount of data PostgreSQL is handling, storing it for further elaboration, such as deciding on which indexes to use to satisfy a query.
>logical replication launcher is a process responsible for handling logical replication.
	Depending on the exact configuration of the cluster, there could be other processes active:

>Background workers: These are processes that can be customized by the user to perform background tasks.
>WAL receiver or WAL sender: These are processes involved in receiving from or sending data to another cluster in replication scenarios.


The main directories available in PGDATA are as follows:
  >base is a directory that contains all the users'' data, including databases, tables, and other objects.
  >global is a directory containing cluster-wide objects.
  >pg_wal is the directory containing the WAL files.
  >pg_stat and pg_stat_tmp are, respectively, the storage of the permanent and temporary statistical information about the status and health of the cluster.


	
Managing Users and Connections	  
	A role can be a single account, a group of accounts, or even both
	a role should express one and only one concept at a time
	CONNECTION LIMIT <n> allows the user to open no more than <n> simultaneous connections to the cluster
	in order to be allowed to interactively log in, the role must also have the LOGIN option
	pg_authid > ie backbones for pg_roles	
	pg_hba.conf
		any change to it > reload the new rules via a HUP signal or by means of a reload command in pg_ctl. 
		kind of firewall table, formerly know as host-based access, that is defined within the pg_hba.conf file.
		The first rule that satisfies the logic is applied, and the others are skipped. 
		each line(rule) in pg_hba.conf:
			<connection-type> 	<database> 	<role> 			<remote-machine> 	<auth-method>
			local/host/hostssl	myDB		+forum_stats		all/ip			scram-sha-256/md5/reject/trust
			local/host/hostssl	myDB		@rejected_users.txt	all/ip			scram-sha-256/md5/reject/trust
			to read the recjected file
				$ sudo cat $PGDATA/rejected_users.txt
		the + preceding the role name ie include all the direct and indirect members.
		the (@), the name is interpreted as a line-separated text file
		can look up settings by querying: select * from pg_settings
	
In PostgreSQL, databases are directories.

PostgreSQL has three types of tables:
	-Temporary tables: Very fast tables, visible only to the user who created them
		create temp table if not exists temp_users 
	-Unlogged tables: Very fast tables to be used as support tables common to all users
	-Logged tables: Regular tables	

	next "Server-Side Programming": The JSON data type
Learn PostgreSQL
Luca Ferrari, Enrico Pirozzi


	
		
