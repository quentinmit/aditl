package Database2;

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

#returns list of uids;
sub importStatusWhere {
    my $self = shift;
    my $string = shift;

    my $conn = $self->{connection};

    my @row;
    my $res = $conn->exec("select uid from import_status where last_success = '$string';");
    my @rlist;

    while(@row = $res->fetchrow()) {
	push(@rlist, $row[0]);
    }

    return @rlist;
}

#returns list of uids;
sub getNewUploads {
    my $self = shift;

    my $conn = $self->{connection};

    my @row;
    my $res = $conn->exec("select uid from import_status where last_success = 'new';");
    my @rlist;

    while(@row = $res->fetchrow()) {
	push(@rlist, $row[0]);
    }

    return @rlist;
}

#returns list of uids;
sub getResizeCompleteUploads {
    my $self = shift;

    my $conn = $self->{connection};

    my @row;
    my $res = $conn->exec("select uid from import_status where last_success = 'resize-complete';");
    my @rlist;

    while(@row = $res->fetchrow()) {
	push(@rlist, $row[0]);
    }

    return @rlist;
}

sub nextPhid {
    my $self = shift;

    my $conn = $self->{connection};

    my @row;
    my $res;
    $res = $conn->exec("select nextval('photos_seq');");
    @row = $res->fetchrow();
    return $row[0];
}

sub insertPhoto {
    my $self = shift;
    my $table = shift;
    my $phid = shift;
    my $uid = shift;
    my $width = shift;
    my $height = shift;
    my $url = shift;
    my $file = shift;
    my $datestamp = shift;

    my $conn = $self->{connection};

    my @row;
    my $res = $conn->exec("select phid from $table where uid = $uid and path = '$file';");
    if($res->fetchrow()) {
        my $query = "update $table set width = $width, height = $height, url = '$url', time = '$datestamp' where uid = $uid and path = '$file';";
	$conn->exec($query);
    } else {
	my $query = "insert into $table (phid, uid, width, height, url, path, time) values ($phid, $uid, $width, $height, '$url', '$file', '$datestamp');";
	$conn->exec($query);
    }
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

sub getZipFilePath {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my $res = $conn->exec("select uploadzippath from users2 where uid = '$uid';");
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
    
# takes uid and returns (first name, last name, email);
sub getinfo {
    my $self = shift;
    my $uid  = shift;
    
    my $conn = $self->{connection};

    my $res = $conn->exec("select first_name, last_name, email from users where uid = $uid;");
    return $res->fetchrow();
}


