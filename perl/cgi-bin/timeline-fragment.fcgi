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

ACCEPT: while ($cgi = new CGI::Fast) {

#unless(defined($cgi->param("uid1")) && defined($cgi->param("uid2")) &&
#   defined($cgi->param("uid3")) && defined($cgi->param("uid4")) &&
#       defined($cgi->param("start")) && defined($cgi->param("end"))) {
#    print $cgi->header();
#    exit;
#}

  my @uids;
  foreach my $i (0..4) {
    my $j = $i+1;
    my $uid = $cgi->param("uid$j");
    if($uid) {
      $uid = int($uid);
      push(@uids, $uid);
    }
  }

  #these are in minutes.
  my $start = $cgi->param("start");
  my $end = $cgi->param("end");

  $start = int($start);
  $end = int($end);

  if($start < 0 || $start > 1440 || $end < 0 || $end > 1440) {
    print $cgi->header();
    next ACCEPT;
  }

  if($end <= $start) {
    print $cgi->header();
    next ACCEPT;
  }

  unless(($start % 15 == 0) && ($end % 15 == 0)) {
    print $cgi->header();
    next ACCEPT;
  }


  print $cgi->header();
  my @images;

  foreach(@uids) {

    #comes back sorted.
    my @thisimages = $db->getPhotoInfoBetween($_, toSqlTime($start), toSqlTime($end));

    my @bucketized;
    #becomes a list of list refs. Each sublist is a list of %photos in time order 
    bucketize(\@thisimages, \@bucketized);

    push(@images, \@bucketized);
  }


  my $html = "<div class=\"fifteen-block\">\n";

  if($start % 60 == 0 || $start % 60 == 30) {
    $html .= "<div style=\"position:absolute; left:0px; height:0px; font-size:10px;" .
	"color:#333333;\">" . niceTime($start) . "</div>\n";
  }

  my $yoff = 8;
  my $line = 0;
  foreach(@images) {
    my @is = @$_;

    if($line == 1) {
	$yoff += 40;
    } else {
	$yoff += 25;
    }

    my $class = "single-timeline";
    if($uids[$line] < 0) {
      $class = "single-timeline-empty";
    }

    $html .= "<div class=\"$class\" style=\"left:0px; top:" . $yoff . "px; height:15px;\">\n";
    foreach(@is) {

      my $xoff = getPixelOffset($start, $_->{time});

      my $slot = ($line == 0)? 1 : 2;

      $html .= "<img class=\"tiny-thumbnail\" id=\"tiny" . $_->{phid} . "\" style=\"top:0 " .
	"px; left:" . $xoff . "px;\" src=\"" . Utils::imageURL($_, "small") .
	  "\" width=\"20\" height=\"15\" onClick=\"photo1Click(" . 
	    $_->{phid} . ", $slot, $xoff, $yoff);\">\n";
    }

    $html .= "</div>";
    $line++;
  }

  $html .= "</div>";

  print $html;

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
    my $outref = shift;

    my %buckets;
    #open(FILE, ">>/tmp/frag.log") or die;

    foreach(@$listref) {
	my @time = Utils::sqlTime($_->{time});
	my $mins = $time[0]*60 + $time[1];
	my $bucket = int($mins / 1.5);
	#print FILE "photo $_->{phid} $_->{time} is in bucket $bucket\n";
	unless(exists($buckets{$bucket})) {
	    $buckets{$bucket} = 1;
	    push(@$outref, $_);
            #print FILE "creating bucket $bucket\n";  
	}
    }

    #close(FILE);
}

    
