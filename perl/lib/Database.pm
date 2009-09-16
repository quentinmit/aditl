package Database;

require Exporter;
@ISA = qw(Exporter);

#@EXPORT_OK = qw(new, connect);
@EXPORT_OK = qw();


use strict;

use Pg; #for DB conectivity.

#good random seed. from programming perl.
srand ( time() ^ ($$ + ($$ << 15)) ); 

# creates new DB object.
sub new {
    my $classname = shift;
    my $object = {};
    bless($object, $classname);
    return $object;
}

#takes database name to connect to.
#returns a 1 if success, 0 otherwise.
#assumes password is empty.
sub connect {
    my $self = shift;
    my $dbname = shift;
    my $conn = Pg::setdb("localhost", "", "", "", $dbname);
    $self->{connection} = $conn;
    my $status = ($conn->status == 0)? 1 : 0;
    return $status
}

# adds the given authToken and returns the token index (used to later retrieve the token),
# which should be added as a cookie to the browser in addition to the token itself.
# The token value should be but may not be unique, so the token index is just a way to
# uniqueley name the token.

# takes user's id, token value.
sub addAuthToken {
    my $self = shift;
    my $uid = shift;
    my $tokenValue = shift;

    my $conn = $self->{connection};

    $conn->exec("delete from cookies where uid = '$uid';");
    # remove user's other cookies.

    my $result = $conn->exec("select nextval('cookies_seq');");
    my @row = $result->fetchrow();
    return 0 unless(@row);
    my $cid = $row[0];

    #not we're not implementing cookies that expire.
    my $query = "insert into cookies (cookie_id, uid, cookie_value)
values ($cid, $uid, $tokenValue);";

    $conn->exec($query);
    return $cid;
}

# takes token index and list ref. Sets list to (token value, uid) on successs, and
# returns 1. Returns 0 if token doesn't exist.
sub getAuthToken {
    my $self = shift;
    my $tokenId = shift;
    my $listref = shift;

    my $conn = $self->{connection};

    my $query = "select cookie_value, uid from cookies where cookie_id = '$tokenId';";
    my $res = $conn->exec($query);

    my @row = $res->fetchrow();

    return 0 unless(@row);

    push(@$listref, @row);
    return 1;

}

sub getPermission {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my $query = "select perm_type from permissions where uid = $uid;";
    my $res = $conn->exec($query);

    my @row = $res->fetchrow();

    return $row[0] or 0;
}



# takes uid and returns email.
sub getEmail {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my $query = "select email from users where uid = '$uid';";
    my $res = $conn->exec($query);

    my @row = $res->fetchrow();

    return 0 unless(@row);

    return $row[0];
}

# returns uid if user exists. 0 otherwise.
sub userExists {
    my $self = shift;
    my $email = shift;
    
    my $conn = $self->{connection};
    my $res = $conn->exec("select uid from users where email = '$email';");
    my @rows = $res->fetchrow();
    if(scalar(@rows) == 0) {
	return 0;
    } else {
	return $rows[0];
    }
}

#takes username and password and returns 1 if a valid pair, 0 otherwise
sub validUser {
    my $self = shift;
    my $email = shift;
    my $password = shift;

    if($email =~ /\'/ || $email =~ /\"/) {
	return 0;
    }

    if($password =~ /\'/ || $password =~ /\"/) {
	return 0;
    }

    my $conn = $self->{connection};

    my $res = $conn->exec("select password from users where email = '$email' and validated = 1;");
    my @row = $res->fetchrow();
    if(scalar(@row) == 0) {
	return 0;
    }
    my $dbpassword = $row[0];
    if($dbpassword eq $password) {
	return 1;
    } else {
	return 0;
    }
}

# registers a new user (not yet validated however)
sub registerUser {
    my $self = shift;
    my $fn = shift;
    my $ln = shift;
    my $email = shift;
    my $pw = shift;
    my $affil = shift;
    my $tk = shift; #validation token.

    my $conn = $self->{connection};

    my $res = $conn->exec("select nextval('users_seq');");
    my @row = $res->fetchrow();
    return 0 unless(@row);
    my $uid = $row[0];
    my $query = "insert into users (uid, email, first_name, last_name, password, affiliation, validate_token) values ($uid, '$email', '$fn', '$ln', '$pw', '$affil', '$tk');";
    $res = $conn->exec($query);
    return $uid;
}

sub completeRegistration {
    my $self = shift;
    my $uid = shift;
    my $token = shift;

    my $conn = $self->{connection};

    my $query = "select validate_token from users where uid = $uid;";
    my $res = $conn->exec($query);
    my @row = $res->fetchrow();
    if(scalar(@row) == 0) {
	return 0;
    }

    my $foundTk = $row[0];
    if($token == $foundTk) {
	$query = "update users set validated = 1 where uid = $uid;";
	$conn->exec($query);
	return 1;
    } else {
	return 0;
    }
}
	


#takes a time in the format 2003-01-03 03:46:00-05 for example
#and returns the hours, minutes, seconds in a list.
sub fixTime {
    shift;
    my $time = shift;
    my @split1 = split(/ /, $time);
    my @split2 = split(/\-/, $split1[1]);
    my @times = split(/:/, $split2[0]);
    return @times;
}

sub howManyRegistered {
    my $self = shift;

    my $conn = $self->{connection};

    my $query = "select count(*) from users;";
    my $res = $conn->exec($query);
    my @row = $res->fetchrow();
    if(scalar(@row) == 0) {
	return 0;
    }

    return $row[0];
}

# sets the zipfilepath attribute in the user2 table.
sub zipFilePath {
    my $self = shift;
    my $uid = shift;
    my $path = shift;

    my $conn = $self->{connection};

    my $res = $conn->exec("select uid from users2 where uid = '$uid';");
    if($res->fetchrow()) {
	$conn->exec("update users2 set uploadzippath = '$path' where uid = '$uid';");
    } else {
	$conn->exec("insert into users2 (uid, uploadzippath) values ($uid, '$path');");
    }
}

# sets the howheard attribute in the users2 table.
sub setHowHeard {
    my $self = shift;
    my $uid = shift;
    my $howheard = shift;

    my $conn = $self->{connection};

    my $res = $conn->exec("select uid from users2 where uid = '$uid';");
    if($res->fetchrow()) {
	$conn->exec("update users2 set howheard = '$howheard' where uid = '$uid';");
    } else {
	$conn->exec("insert into users2 (uid, howheard) values ($uid, '$howheard');");
    }
}

# populates refd list with references to hash objects.
# each has has keys 'email' and 'uid';
sub getAllEmails {
    my $self = shift;
    my $listref = shift;

    my $conn = $self->{connection};
    my $res = $conn->exec("select uid, first_name, last_name, email from users;");

    my @row;
    while(@row = $res->fetchrow()) {
	my %hash;
	$hash{uid} = $row[0];
	$hash{email} = $row[3];
	$hash{name} = $row[1] . " " . $row[2];
	push(@$listref, \%hash);
    }
}

# searches the given column and sets
# refed list to contain hashes with keys 'email',
# 'fn', 'ln', 'uid'.
sub search {
    my $self = shift;
    my $search = shift;
    my $column = shift;
    my $listref = shift;

    $search =~ s/\W//g;

    my $conn = $self->{connection};


    my @row;
    my $res = $conn->exec("select uid, first_name, last_name, email from users where $column like '%$search%';");
    while(@row = $res->fetchrow()) {
	my %hash;
	$hash{uid} = $row[0];
	$hash{email} = $row[3];

	my $fn = uc(substr($row[1], 0, 1)) . substr($row[1], 1);
	my $ln = uc(substr($row[2], 0, 1)) . substr($row[2], 1);

	$hash{fn} = $fn;
	$hash{ln} = $ln;
	push(@$listref, \%hash);
    }
}

# takes uid and returns (first name, last name, email);
sub getinfo {
    my $self = shift;
    my $uid  = shift;
    
    my $conn = $self->{connection};

    my $res = $conn->exec("select first_name, last_name, email from users where uid = $uid;");
    return $res->fetchrow();
}

#returns (total # photos, total captions, total comments)
sub getinfo2 {
    my $self = shift;
    my $uid  = shift;
    
    my $conn = $self->{connection};

    my @ret;
    my @row;

    my $res = $conn->exec("select count(*) from med_photos where uid = '$uid';");
    @row = $res->fetchrow();
    push(@ret, $row[0]);


    return @ret;
}



# takes user's uid and sets list to
# contain hashes with keys uid, email,
# first name, last name for the given
# user's friends.
sub friends {
    my $self = shift;
    my $uid = shift;
    my $listref = shift;

    my $conn = $self->{connection};

    my @row;
    my @uids;
    my $res = $conn->exec("select friend_uid from friends where uid = $uid;");
    while(@row = $res->fetchrow()) {
	push(@uids, $row[0]);
    }

    foreach(@uids) {
	my @info = $self->getinfo($_);
	my %hash;
	$hash{uid} = $_;
	$hash{email} = $info[2];

	my $fn = uc(substr($info[0], 0, 1)) . substr($info[0], 1);
	my $ln = uc(substr($info[1], 0, 1)) . substr($info[1], 1);

	$hash{fn} = $fn;
	$hash{ln} = $ln;

	push(@$listref, \%hash);
    }
}

# takes user's uid, friend's uid, and an integer n and tries to add the person
# represented by the uid to the friends table. If there are
# n or more friends already (the friend limit), returns 0
# otherwise returns 1;
sub addfriend {
    my $self = shift;
    my $uid = shift;
    my $fruid = shift;
    my $n = shift;
    
    my $conn = $self->{connection};

    my @row;
    my $res = $conn->exec("select count(*) from friends where uid = $uid;");
    @row = $res->fetchrow();
    if($row[0] >= $n) {
	return 1;
    }

    $res = $conn->exec("select friend_uid from friends where uid = $uid and friend_uid = $fruid;");
    if($res->fetchrow()) {
	return 0;
    }

    $res = $conn->exec("select count(*) from users where uid = $fruid;");
    @row = $res->fetchrow();
    unless($row[0] == 1) {
	return 0;
    }
    
    $res = $conn->exec("select nextval('friends_seq');");
    @row = $res->fetchrow();
    my $next = $row[0];
    
    $conn->exec("insert into friends (friend_id, uid, friend_uid) values ($next, $uid, $fruid);");
    return 0;
}

sub delfriend {
    my $self = shift;
    my $uid = shift;
    my $fruid = shift;

    my $conn = $self->{connection};

    $conn->exec("delete from friends where uid = $uid and friend_uid = $fruid;");
}

sub friendcount {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my $res = $conn->exec("select count(*) from friends where uid = $uid;");
    my @row = $res->fetchrow();
    return $row[0];
}

sub setImportStatus {
    my $self = shift;
    my $uid = shift;
    my $message = shift;

    my $conn = $self->{connection};

    my $res = $conn->exec("select uid from import_status where uid = '$uid';");
    if($res->fetchrow()) {
	$conn->exec("update import_status set last_success = '$message' where uid = '$uid';");
    } else {
	$conn->exec("insert into import_status (uid, last_success) values ($uid, '$message');");
    }
}



sub getRandomFrontPhoto {
    my $self = shift;
    my $table = shift;
    my $hashref = shift;

    my $conn = $self->{connection};

    #date_written is used to keep track of which frontpage images were recently selected, so we don't 
    #reshow them.
    my $res = $conn->exec("select phid from circles where circle_type = 1 order by last_date limit 30");
    my @images;
    while(my @row = $res->fetchrow) {
	push(@images, $row[0]);
    }

    my $i = int(rand(scalar(@images)));
    my $phid = $images[$i];

    $conn->exec("update circles set last_date = now() where phid = $phid");

    $self->photoInfo($phid, $table, $hashref);
}

# takes a table name which is the actual table to return
# the image from (the selection of an image occurs in the
# large_photos table...assuming all image tables contain same
# set of images as far as phid goes...just different sizes
# urls, etc). See photoInfo for what info is returned.
sub randomImage {
    my $self = shift;
    my $table = shift;
    
    my $hashref = shift;

    my $conn = $self->{connection};
    my $res = $conn->exec("select phid from large_photos;");

    my @phids;
    my @row;


    while(@row = $res->fetchrow()) {
	push(@phids, $row[0]);
    }

    my $i = rand(scalar(@phids));
    my $phid = $phids[$i];


    $self->photoInfo($phid, $table, $hashref);
}

sub photoInfo {
    my $self = shift;
    my $phid = shift;
    my $table = shift;
    my $hashref = shift;

    my $conn = $self->{connection};
    my $q = "select phid, uid, width, height, time, time_offset, url, path from $table where phid = $phid;";

    my $res = $conn->exec($q);
    my @row = $res->fetchrow();

    
    
    $hashref->{phid} = $row[0];
    $hashref->{uid} = $row[1];
    $hashref->{width} = $row[2];
    $hashref->{height} = $row[3];
    $hashref->{time} = $row[4];
    $hashref->{offset} = $row[5];
    $hashref->{url} = $row[6];
    $hashref->{file} = $row[7];

}

# takes a uid, a beginning time "yyyy-mm-dd hh:mm:ss", and ending time (same format)
# and a returns a list of phids for photos in that time.
sub getPhotosBetween {
    my $self = shift;
    my $uid = shift;
    my $start = shift;
    my $end = shift;

    my $conn = $self->{connection};

    my $query;
    #if($uid == -2) {
	#$query = "select phid from large_photos where time > '$start' and time <= '$end' order by time;";
    #} else {
	$query = "select phid from large_photos where uid = $uid and time > '$start' and time <= '$end' order by time;";
    #}
    
    #print $query;
    my $res = $conn->exec($query);
    my @phids;
    my @row;
    while(@row = $res->fetchrow()) {
	push(@phids, $row[0]);
    }

    return @phids;
}

sub photoVote {
    my $self = shift;
    my $phid = shift;
    my $uid = shift;
    my $type = shift;

    my $conn = $self->{connection};
    my $res = $conn->exec("select circle_type from circles where phid = $phid;");
    my $query;
    if($res->fetchrow()) {
	$query = "update circles set circle_type = $type where phid = $phid;";
    } else {
	$query = "insert into circles (phid, circle_type, last_date) values ($phid, $type, now());";
    }
    $conn->exec($query);
}

#populates list with uids of users with photos in the db.
sub usersWithPhotos {
    my $self = shift;
    my $ref = shift;

    my $conn = $self->{connection};
    my $query = "select distinct uid from med_photos;";
    my $res = $conn->exec($query);

    my @rows;
    while(@rows = $res->fetchrow()) {
	push(@$ref, $rows[0]);
    }
}

#returns list of friends' uids.
sub getFriends {
    my $self = shift;
    my $uid = shift;
    
    my $conn = $self->{connection};
    my $query = "select friend_uid from friends where uid = $uid order by friend_uid;";
    my $res = $conn->exec($query);
    
    my @row;
    my @ret;

    while(@row = $res->fetchrow()) {
	push(@ret, $row[0]);
    }

    return @ret;
}

sub getCaption {
    my $self = shift;
    my $phid = shift;

    my $conn = $self->{connection};
    my $query = "select caption from captions where phid = $phid;";
    my $res = $conn->exec($query);
    my @row = $res->fetchrow();
    return $row[0];
}

#assumes caption has already been made safe...i.e no unescaped ' characters.
sub setCaption {
    my $self = shift;
    my $phid = shift;
    my $caption = shift;

    my $conn = $self->{connection};
    my $query = "delete from captions where phid = $phid;";
    $conn->exec($query);
    $query = "insert into captions values ($phid, '$caption');";
    $conn->exec($query);
}
