package Upload;

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(process_upload);

use strict;

use lib "./";
use Settings;
use File::Spec::Functions;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

our %SIZES = (
	      small => "50x50",
	      medium => "x225",
	      large => "600x350",
	     );

sub process_upload {
  my ($db, $uid, $file) = @_;

  if ($file =~ m|\.zip$|) {
    return process_zip($db, $uid, $file);
  } else {
    return process_image($db, $uid, $file);
  }
}

sub process_zip {
  my ($db, $uid, $file) = @_;

  my $zip = Archive::Zip->new();

  unless ( $zip->read($file) == AZ_OK ) {
    return "FAIL:Unable to read Zip archive";
  }

  my $outdir = $file."-files";
  -d $outdir || mkdir($outdir) or return "FAIL:Unable to make output directory $outdir: $!";
  my @results;
  my $i;
  for my $member ($zip->members()) {
    next if $member->isDirectory();
    my $filename = $member->fileName();
    my $extension = ".jpg";
    if ($filename =~ m|(\.([^.]+))$|) {
      $extension = $1;
    }
    my $out = catfile($outdir, $i++.$extension);
    if ($zip->extractMember($member, $out) == AZ_OK) {
      push @results, process_image($db, $uid, $out);
    } else {
      push @results, "FAIL:Couldn't extract $filename from zip archive";
    }
  }
  return @results;
}

sub process_image ($$) {
  my ($db, $uid, $file) = @_;

  my $conv = Settings::settings("convert");

  my $ret = eval {
    my @date;
    Utils::exiftime($file, \@date) or die "Couldn't extract time";
    my $datestamp = join("-", ($date[0], $date[1], $date[2])) . " " .
      join(":", ($date[3], $date[4], $date[5]));
    my $phid = $db->nextPhid;

    umask(002);

    my $userroot = catdir(Settings::settings("rootPhotoDir"), $uid);

    -d $userroot || mkdir($userroot) or die "Couldn't make your photo directory $userroot: $!";

    foreach my $size (keys %SIZES) {
      my $sizedir = catdir($userroot, $size);
      -d $sizedir || mkdir($sizedir) or die "Couldn't mkdir: $!";

      system($conv, $file, "-geometry", $SIZES{$size}, catfile($sizedir, "$phid.jpg"));
    }

    $db->insertPhoto($phid, $uid, $datestamp, $file);
    return "SUCCESS:$uid/small/$phid.jpg";
  };
  if ($@) {
    return "FAIL:$@";
  } else {
    return $ret;
  }
}
