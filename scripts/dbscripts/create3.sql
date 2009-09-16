create table import_status (
uid int2 primary key,
last_success text);

grant all on import_status to public;


create table votes (
phid int2,
uid int2,
vote_type int2);

grant all on votes to public;