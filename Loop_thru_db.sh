#!/bin/bash
#created by Monktar Bello 7/18/2023

# Define the PostgreSQL connection parameters
HOST="localhost"
PORT="5432"
USERNAME="your_username"
PASSWORD="your_password" # attention if contains special kraters, then enclose with single quote eg. PASSWORD="Monkt@rM\$2022" or Escape Special Characters.eg. PASSWORD="Monkt@rM\$2022"

##if prefer to run .sql and schedule with crontab
PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USERNAME -w -d $DB -f /var/lib/postgresql/scripts/db_test.sql

# crontab -e 
######  use  13:55 March 4th 2025
# 55 13 4 3 2 /bin/bash /var/lib/postgresql/scripts/db_run_sql.sh > db_run_sql.log 2>&1


# Get the list of databases
DATABASES=$(PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USERNAME -w -t -d postgres -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')")

echo "Running query on database: yes ooooh"

# Loop through each database and run the query
for DB in $DATABASES; do
  echo "Running query on database: $DB"
  #PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USERNAME -w -d $DB -c "select table_schema, table_name from information_schema.views where table_name not like 'pg_%'"
  # PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USERNAME -w -d $DB -c "
		# SELECT concat('revoke all privileges on all functions in schema  ', n.nspname , ' from mbello; ')
		# FROM pg_class C
		# LEFT JOIN pg_namespace N
			# ON (N.oid = C.relnamespace)
		# WHERE nspname NOT IN ('pg_catalog', 'information_schema')
		# GROUP BY nspname limit 2 ;
  # "
  #PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USERNAME -w -d $DB -c "Select table_name, column_name from information_schema.columns t where column_name like '%payer%' limit 2;"
  PGPASSWORD=$PASSWORD psql -h $HOST -p $PORT -U $USERNAME -w -d $DB -c "SELECT routine_name,routine_catalog, routine_schema, routine_type FROM information_schema.routines  where routine_name like '%sp_delete%' or routine_definition like '%sp_delete%' limit 2"
  
done
