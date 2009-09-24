package Upload;

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(process_upload);

use strict;

use lib "./";
use Settings;
use File::Spec::Functions;

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
