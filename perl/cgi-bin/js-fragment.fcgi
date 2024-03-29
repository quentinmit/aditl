#!/usr/bin/perl

use strict;

use lib "../lib";
use Database;
use Settings;
use Template;
use Utils;

use CGI::Fast qw(-debug :standard);
$CGI::DISABLE_UPLOADS = 1;

use vars qw($cgi $db);

$db = Database->new();
$db->connect(Settings::settings("dbName"));

ACCEPT: while($cgi = new CGI::Fast) {

  unless(defined($cgi->param("uid1")) && defined($cgi->param("uid2")) &&
	 defined($cgi->param("uid3")) && defined($cgi->param("uid4")) &&
	 defined($cgi->param("start")) && defined($cgi->param("end"))) {
    print $cgi->header();
    print "//Missing parameter\n";
    next ACCEPT;
  }

  my @uids;
  foreach my $i (0..3) {
    my $j = $i+1;
    $uids[$i] = $cgi->param("uid$j");
    $uids[$i] = int($uids[$i]);
  }

  #these are in minutes.
  my $start = $cgi->param("start");
  my $end = $cgi->param("end");

  $start = int($start);
  $end = int($end);

  if($start < 0 || $start > 1440 || $end < 0 || $end > 1440) {
    print $cgi->header();
    print "//Invalid times\n";
    next ACCEPT;
  }

  if($end <= $start) {
    print $cgi->header();
    print "//Start time after end time\n";
    next ACCEPT;
  }

  unless(($start % 15 == 0) && ($end % 15 == 0)) {
    print $cgi->header();
    print "//Start or end time doesn't line up\n";
    next ACCEPT;
  }


  print $cgi->header();
  my @images;

  foreach(@uids) {
    my @thisimages = $db->getPhotoInfoBetween($_, toSqlTime($start), toSqlTime($end));

    #print toSqlTime($start);

    #print @p;

    bucketize(\@thisimages);

    push(@images, \@thisimages);
  }

  my $js = "";

  foreach(@images) {
    my @is = @$_;

    foreach(@is) {

      my @time = Utils::sqlTime($_->{time}, $_->{offset});
      my $tstring = "$time[0]:$time[1]:$time[2]";

      my @photographer = $db->getinfo($_->{uid});
      my $fn = $photographer[0];
      my $ln = $photographer[1];

      my $photogName = lc($fn) . " " . lc($ln);

      my $caption = "";
      $caption = $_->{caption};
      $caption = Utils::summary($caption, 20);

      $js .= "addPhoto(" . $_->{phid} . ", " . $_->{lookupid} . ", \"" .
	Utils::imageURL($_,"medium") . "\", " . $_->{medium_width} .
	    ", \"$tstring\", \"$photogName\", \"$caption\", \"\"); ";	
    }
  }

  print $js;
}

sub getPixelOffset {
    my $start = shift;
    my $time = shift;

    
    my @timel = Utils::sqlTime($time, 0);

    my $seconds = $timel[0]*3600 + $timel[1]*60 + $timel[2];

    # num of seconds into this fifteen minute window that we are.
    my $secondsOff = $seconds - ($start * 60);

    my $ticksOff = int($secondsOff / 90);
    
    #20 is width in pixels of tiny thumbnails.
    my $pixOff = $ticksOff * 20;

    return $pixOff;
}

    



sub toSqlTime {
    my $dayminute = shift;

    my $day = Settings::settings("eventDate");
    my $hour = int($dayminute / 60);
    my $minute = $dayminute % 60;
    
    return "$day $hour:$minute:00";
}

sub niceTime {
    my $dayminute = shift;

    my $hour = int($dayminute / 60);
    my $minute = $dayminute % 60;

    return sprintf("%02d:%02d", $hour, $minute);
}


sub bucketize {
    my $listref = shift;

    my %buckets;

    foreach(@$listref) {
	my @time = Utils::sqlTime($_->{time});
	my $mins = $time[0]*60 + $time[1];
	my $bucket = int($mins / 1.5);
	unless(exists($buckets{$bucket})) {
	    $buckets{$bucket} = $_->{phid};
	}
	$_->{lookupid} = $buckets{$bucket};
    }
}
