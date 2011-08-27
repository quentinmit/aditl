package Settings;

use vars qw(%settings);

$settings{"email"} = "aditl\@mit.edu";

$settings{"dbName"} = "aditl2009";
$settings{"pathBase"} = "/usr/local/aditl2009";
$settings{"urlBase"} = "http://aditl.mit.edu";

$settings{"templateLib"} = $settings{"pathBase"} . "/templates";
$settings{"logDirectory"} = $settings{"pathBase"} . "/logs";
$settings{"scratchDirectory"} = "/srv/aditl2009/scratch";
$settings{"incomingDir"} = "/srv/aditl2009/incoming";
$settings{"rootPhotoDir"} = "/srv/aditl2009/photoroot";
$settings{"tinyBarcodePath"} = "/srv/aditl2009/photoroot/tiny-barcodes";

$settings{"SMTPHost"} = "outgoing.mit.edu";

$settings{"validateURL"} = $settings{"urlBase"} . "/2009/validate";
$settings{"registerURL"} = $settings{"urlBase"} . "/2009/register";
$settings{"phototestURL"} = $settings{"urlBase"} . "/2009/phototest";
$settings{"uploadURL"} = $settings{"urlBase"} . "/2009/upload";
$settings{"loginURL"} = $settings{"urlBase"} . "/2009/login";
$settings{"photoURLBase"} = $settings{"urlBase"} . "/2009/photos";
$settings{"frontURL"} = $settings{"urlBase"} . "/2009/front";
$settings{"timelineURL"} = $settings{"urlBase"} . "/2009/timeline";
$settings{"htmlFragmentURL"} = $settings{"urlBase"} . "/2009/timeline-fragment.fcgi";
$settings{"jsFragmentURL"} = $settings{"urlBase"} . "/2009/js-fragment.fcgi";
$settings{"tinyBarcodeURL"} = $settings{"urlBase"} . "/2009/photos/tiny-barcodes";
$settings{"selectUserURL"} = $settings{"urlBase"} . "/2009/select-user";
$settings{"photoURL"} = $settings{"urlBase"} . "/2009/photo";


$settings{"friendLimit"} = 4;

$settings{"exiftagsCommand"} = "/usr/bin/exiftags -a";
$settings{"unzip"} = "/usr/bin/unzip";
$settings{"convert"} = "/usr/bin/convert";
$settings{"identify"} = "/usr/bin/identify";

$settings{"colorManipLightness"} = 200;
#$settings{"colorManipLightness"} = 240;
$settings{"colorManipSat"} = 225;
#$settings{"colorManipSat"} = 230;

$settings{"eventDate"} = "2009-09-24";

sub settings {
    my $setting = shift;
    if(exists($settings{$setting})) {
	return $settings{$setting};
    } else {
	die "$setting is not a valid setting\n";
    }
}




