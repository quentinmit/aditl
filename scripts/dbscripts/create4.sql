create table captions (
phid int2 primary key,
caption text);

grant all on captions to public;

create table photos (
phid int2 primary key default nextval('photos_seq'),
uid int2 not null,
caption text,
time timestamp,
original_path text unique);
grant all on photos to public;


-- create type photo_size as enum ('small', 'medium', 'large', 'original');
-- create table photo_sizes (
-- phid int primary key,
-- size photo_size,
-- width int2 default 0,
-- height int2 default 0,
-- url text,
-- path text);


