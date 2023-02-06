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


The maintenance processes are as follows:

>checkpointer is a process responsible for executing the checkpoints, which are points in time where the database ensures that all the data is actually stored persistently on the disk.
>background writer is responsible for helping to push the data out of the memory to permanent storage.
>walwriter is responsible for writing out the Write-Ahead Logs (WALs), the logs that are needed to ensure data reliability even in the case of a database crash.
>stats collector is a process that monitors the amount of data PostgreSQL is handling, storing it for further elaboration, such as deciding on which indexes to use to satisfy a query.
>logical replication launcher is a process responsible for handling logical replication.
	Depending on the exact configuration of the cluster, there could be other processes active:

>Background workers: These are processes that can be customized by the user to perform background tasks.
>WAL receiver or WAL sender: These are processes involved in receiving from or sending data to another cluster in replication scenarios.

Learn PostgreSQL
Luca Ferrari, Enrico Pirozzi

Getting to Know Your Cluster
		The template databases
		
2/6/2023 config files, install new postgresql, run command for diff versions of postgresql hosted:start, stop, reload, postgresql processes