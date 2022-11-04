create user mbello with PASSWORD 'xxxxxxxxxxxxxxxxxxxxxx' valid until 'infinity';

alter USER mbello WITH PASSWORD 'xxxxxxxxxxxxxxxxxxxxxx' VALID UNTIL '2022-10-31';

grant medrx_rw to mbello;

grant db_reader to mbello;

comment on role mbello is 'Monktar Bello, DBA';

drop user mbello;


create user mbellotest;

alter role mbellotest with nosuperuser;

alter role mbellotest with createdb;

alter role mbellotest with createrole;

