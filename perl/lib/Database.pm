package Database;

require Exporter;
@ISA = qw(Exporter);

#@EXPORT_OK = qw(new, connect);
@EXPORT_OK = qw();


use strict;

use DBI;

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
    my $conn = DBI->connect("dbi:Pg:dbname=$dbname", '', '', {AutoCommit => 1});
    $self->{connection} = $conn;
    if (!$conn) {
	warn $DBI::errstr;
	return 0;
    }
    return 1;
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

    $conn->do("delete from cookies where uid = ?;", undef, $uid);
    # remove user's other cookies.

    my @row = $conn->selectrow_array("select nextval('cookies_seq')");
    return 0 unless(@row);
    my $cid = $row[0];

    #not we're not implementing cookies that expire.
    $conn->do("insert into cookies (cookie_id, uid, cookie_value) values (?,?,?)", undef, $cid, $uid, $tokenValue);
    return $cid;
}

# takes token index and list ref. Sets list to (token value, uid) on successs, and
# returns 1. Returns 0 if token doesn't exist.
sub getAuthToken {
    my $self = shift;
    my $tokenId = shift;
    my $listref = shift;

    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select cookie_value, uid from cookies where cookie_id = ?", undef, $tokenId);

    return 0 unless(@row);

    push(@$listref, @row);
    return 1;

}

sub getPermission {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select perm_type from permissions where uid = ?", undef, $uid);

    return $row[0] or 0;
}



# takes uid and returns email.
sub getEmail {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select email from users where uid = ?", undef, $uid);

    return 0 unless(@row);

    return $row[0];
}

# returns uid if user exists. 0 otherwise.
sub userExists {
    my $self = shift;
    my $email = shift;
    
    my $conn = $self->{connection};
    my @rows = $conn->selectrow_array("select uid from users where email = ?", undef, $email);
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

    my @row = $conn->selectrow_array("select password from users where email = ? and validated = 1", undef, $email);
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

    $conn->do("insert into users (uid, email, first_name, last_name, password, affiliation, validate_token) values (nextval('users_seq'), ?,?,?,?,?,?)", undef, $email, $fn, $ln, $pw, $affil, $tk);

    my @row = $conn->selectrow_array("select currval('users_seq')");
    return $row[0] or 0;
}

sub completeRegistration {
    my $self = shift;
    my $uid = shift;
    my $token = shift;

    my $conn = $self->{connection};

    # N.B. do() returns the number of affected rows, so 1 = success, 0 = failure
    return $conn->do("update users set validated = 1 where uid = ? and validate_token = ?", undef, $uid, $token);
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


#counts how many registered
sub howManyRegistered {
    my $self = shift;

    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select count(*) from users;");
    if(scalar(@row) == 0) {
	return 0;
    }

    return $row[0];
}

#counts how many photos total
sub howManyPhotos {
    my $self = shift;

    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select count(*) from photos;");
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

    $conn->do("update users set uploadzippath = ? where uid = ?", undef, $path, $uid);
}

# sets the howheard attribute in the users2 table.
sub setHowHeard {
    my $self = shift;
    my $uid = shift;
    my $howheard = shift;

    my $conn = $self->{connection};

    $conn->do("update users set howheard = ? where uid = ?", undef, $howheard, $uid);
}

# populates refd list with references to hash objects.
# each has has keys 'email' and 'uid';
sub getAllEmails {
    my $self = shift;
    my $listref = shift;

    my $conn = $self->{connection};

    my $sth = $conn->prepare("select uid, first_name, last_name, email from users;");
    $conn->execute;

    while(my @row = $sth->fetchrow_array()) {
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


    my $sth = $conn->prepare("select uid, first_name, last_name, email from users where $column like ?");
    $sth->execute("%$search%");
    while(my @row = $sth->fetchrow_array()) {
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

    return ($conn->selectrow_array("select first_name, last_name, email from users where uid = ?", undef, $uid));
}

#returns (total # photos, total captions, total comments)
sub getinfo2 {
    my $self = shift;
    my $uid  = shift;
    
    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select count(*) from photos where uid = ?", undef, $uid);

    return $row[0] or 0;
}

sub nextPhid {
  my ($self) = @_;

  my $conn = $self->{connection};

  my @row = $conn->selectrow_array("select nextval('photos_seq')");

  return $row[0] || 0;
}

sub insertPhoto {
  my ($self, $phid, $uid, $time, $file, $md5, $medium_size) = @_;

  my $conn = $self->{connection};

  $conn->do("INSERT INTO photos (phid, uid, time, original_path, original_md5, medium_size) VALUES (?, ?, ?, ?, ?, ?)",
	    undef, $phid, $uid, $time, $file, $md5, join(',', @$medium_size));
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
    my @uids = map { @$_ } $conn->selectall_arrayref("select friend_uid from friends where uid = ?", undef, $uid);

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

    my @row = $conn->selectrow_array("select count(*) from friends where uid = ?", undef, $uid);
    if($row[0] >= $n) {
	return 1;
    }

    #NB: Constraints on the table prevent duplicates or non-existing uids
    $conn->do("insert into friends (uid, friend_uid) values (?, ?)", undef, $uid, $fruid);
    return 0;
}

sub delfriend {
    my $self = shift;
    my $uid = shift;
    my $fruid = shift;

    my $conn = $self->{connection};

    $conn->do("delete from friends where uid = ? and friend_uid = ?", undef, $uid, $fruid);
}

sub friendcount {
    my $self = shift;
    my $uid = shift;

    my $conn = $self->{connection};

    my @row = $conn->selectrow_array("select count(*) from friends where uid = ?", undef, $uid);
    return $row[0] or 0;
}

sub setImportStatus {
    my $self = shift;
    my $uid = shift;
    my $message = shift;

    my $conn = $self->{connection};

    # N.B. We can just ignore the error if there's a dupe
    $conn->do("insert into import_status (last_success, uid) values (?, ?)", undef, $message, $uid);
    $conn->do("update import_status set last_success = ? where uid = ?", undef, $message, $uid);
}



sub getRandomFrontPhoto {
    my $self = shift;
    my $hashref = shift;

    my $conn = $self->{connection};

    #date_written is used to keep track of which frontpage images were recently selected, so we don't 
    #reshow them.
    my @images = @{$conn->selectcol_arrayref("select phid from circles where circle_type = 1 order by last_date limit 30")};

    my $i = int(rand(scalar(@images)));
    my $phid = $images[$i];

    $conn->do("update circles set last_date = now() where phid = ?", undef, $phid);

    $self->photoInfo($phid, $hashref);
}

# takes a table name which is the actual table to return
# the image from (the selection of an image occurs in the
# large_photos table...assuming all image tables contain same
# set of images as far as phid goes...just different sizes
# urls, etc). See photoInfo for what info is returned.
sub randomImage {
    my $self = shift;

    my $hashref = shift;

    my $conn = $self->{connection};
    my ($phid) = $conn->selectrow_array("select phid from photos WHERE phid NOT IN (select phid from circles) order by random() limit 1");

    $self->photoInfo($phid, $hashref);
}

sub randomUsersWithPhotos {
  my ($self, $limit) = @_;
  my $uids = $self->{connection}->selectcol_arrayref("select uid from (select distinct uid from photos) t1 order by random() limit ?", undef, $limit);
  return @$uids;
}

sub getPhotoByMD5 {
  my ($self, $md5) = @_;

  my ($phid) = $self->{connection}->selectrow_array("select phid from photos where original_md5 = ?", undef, $md5);
  return $phid;
}

sub getNextPhoto {
  my ($self, $uid, $phid) = @_;

  my ($next) = $self->{connection}->selectrow_array("select phid from photos where uid = ? and (time > (select time from photos where phid = ?) or (time = (select time from photos where phid = ?) and phid > ?)) order by time, phid limit 1", undef, $uid, $phid, $phid, $phid);
  return $next;
}

sub getPreviousPhoto {
  my ($self, $uid, $phid) = @_;

  my ($previous) = $self->{connection}->selectrow_array("select phid from photos where uid = ? and (time < (select time from photos where phid = ?) or (time = (select time from photos where phid = ?) and phid < ?)) order by time desc, phid desc limit 1", undef, $uid, $phid, $phid, $phid);
  return $previous;
}

sub photoInfo {
    my $self = shift;
    my $phid = shift;
    my $hashref = shift;

    my $conn = $self->{connection};
    my $sth = $conn->prepare("select phid, uid, time, original_path, medium_size[0] as medium_width, medium_size[1] as medium_height from photos where phid = ?");
    $sth->execute($phid);
    
    my $row = $sth->fetchrow_hashref;

    @{$hashref}{keys %$row} = values %$row;
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
    my $phids = $conn->selectcol_arrayref("select phid from photos where uid = ? and time > ? and time <= ? order by time", undef, $uid, $start, $end);

    return @$phids;
}

# takes a uid, a beginning time "yyyy-mm-dd hh:mm:ss", and ending time (same format)
# and a returns a list of phids for photos in that time.
sub getAllPhotosBetween {
    my $self = shift;
    my $start = shift;
    my $end = shift;

    my $conn = $self->{connection};

    my $query;
    my $phids = $conn->selectcol_arrayref("select phid from photos where time > ? and time <= ? order by time", undef, $start, $end);

    return @$phids;
}

# takes a uid, a beginning time "yyyy-mm-dd hh:mm:ss", and ending time (same format)
# and a returns a list of phids for photos in that time.
sub getPhotoInfoBetween {
    my $self = shift;
    my $uid = shift;
    my $start = shift;
    my $end = shift;

    my $conn = $self->{connection};

    my $query;
    my $sth = $conn->prepare("select phid, uid, time, caption, original_path, medium_size[0] as medium_width, medium_size[1] as medium_height from photos where uid = ? and time > ? and time <= ? order by time");
    $sth->execute($uid, $start, $end);

    my @photos;
    while (my $row = $sth->fetchrow_hashref) {
      push @photos, $row;
    }

    return @photos;
}

# takes a a beginning time "yyyy-mm-dd hh:mm:ss", and ending time (same format)
# and a returns a list of phids for photos in that time.
sub getAllPhotoInfoBetween {
    my $self = shift;
    my $start = shift;
    my $end = shift;

    my $conn = $self->{connection};

    my $query;
    my $sth = $conn->prepare("select phid, uid, time, caption, original_path, medium_size[0] as medium_width, medium_size[1] as medium_height from photos where time > ? and time <= ? order by time");
    $sth->execute($start, $end);

    my @photos;
    while (my $row = $sth->fetchrow_hashref) {
      push @photos, $row;
    }

    return @photos;
}

sub photoVote {
    my $self = shift;
    my $phid = shift;
    my $uid = shift;
    my $type = shift;

    my $conn = $self->{connection};
    my $query;

    if ($conn->selectrow_array("select circle_type from circles where phid = ?", undef, $phid)) {
	$query = "update circles set circle_type = ? where phid = ?";
    } else {
	$query = "insert into circles (circle_type, phid, last_date) values (?, ?, now())";
    }

    $conn->do($query, undef, $type, $phid);
}

#populates list with uids of users with photos in the db.
sub usersWithPhotos {
    my $self = shift;

    my $conn = $self->{connection};
    return @{$conn->selectcol_arrayref("select distinct uid from photos")};
}

sub userInfoWithPhotos {
  my $self = shift;

  my $conn = $self->{connection};
  my $sth = $conn->prepare("select uid, lower(first_name) as fn, lower(last_name) as ln, lower(last_name) as name from users where uid in (select distinct uid from photos)");
  $sth->execute;

  my @users;
  while (my $row = $sth->fetchrow_hashref) {
    push @users, $row;
  }
  return @users;
}

#returns list of friends' uids.
sub getFriends {
    my $self = shift;
    my $uid = shift;
    
    my $conn = $self->{connection};
    return @{$conn->selectcol_arrayref("select friend_uid from friends where uid = ? order by friend_uid", undef, $uid)};
}

sub getCaption {
    my $self = shift;
    my $phid = shift;

    my $conn = $self->{connection};
    return $conn->selectrow_array("select caption from photos where phid = ?", undef, $phid);
}

#assumes caption has already been made safe...i.e no unescaped ' characters.
sub setCaption {
    my $self = shift;
    my $phid = shift;
    my $caption = shift;

    my $conn = $self->{connection};
    $conn->do("UPDATE photos SET caption = ? WHERE phid = ?", undef, $caption, $phid);
}
