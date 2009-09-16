
create table users (
uid int2 primary key,
email text unique,
first_name text,
last_name text,
login_name text,
password text,
affiliation text,
validated int2 default 0,
validate_token text);

create sequence users_seq increment 1 start 1;
grant all on users to public;
grant all on users_seq to public;



create table large_photos (
phid int primary key,
uid int2 not null,
width int2 default 0,
height int2 default 0,
url text,
path text,
rotation int2 default 0,
time timestamp,
time_offset int2 default 0,
preferred int2 default 0);

grant all on large_photos to public;

create table med_photos (
phid int primary key,
uid int2 not null,
width int2 default 0,
height int2 default 0,
url text,
path text,
rotation int2 default 0,
time timestamp,
time_offset int2 default 0,
preferred int2 default 0);

grant all on med_photos to public;

create table small_photos (
phid int primary key,
uid int2 not null,
width int2 default 0,
height int2 default 0,
url text,
path text,
rotation int2 default 0,
time timestamp,
time_offset int2 default 0,
preferred int2 default 0);

grant all on small_photos to public;

create sequence photos_seq increment 1 start 1;
grant all on photos_seq to public;

create table friends (
friend_id int primary key,
uid int2 not null,
friend_uid int2 not null,
preferred int2 default 0);

create sequence friends_seq increment 1 start 1;

grant all on friends to public;
grant all on friends_seq to public;


create table timeline_cache (
cache_id int primary key,
uid int2 not null,
minute_begin int2 not null,
path text not null);

create sequence timeline_cache_seq increment 1 start 1;

grant all on timeline_cache to public;
grant all on timeline_cache_seq to public;


create table circles (
phid int not null,
circle_type int2 default 0,
last_date timestamp);

create sequence circles_seq increment 1 start 1;

grant all on circles to public;
grant all on circles_seq to public;


create table cookies (
cookie_id int primary key,
uid int2 not null,
cookie_value text not null,
expires timestamp);

create sequence cookies_seq increment 1 start 1;

grant all on cookies to public;
grant all on cookies_seq to public;


create table permissions (
uid int2 primary key,
perm_type int2 default 0);

grant all on permissions to public;
