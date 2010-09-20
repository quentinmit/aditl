package Settings;

use vars qw(%settings);

$settings{"email"} = "aditl\@mit.edu";

$settings{"dbName"} = "aditl2010";
$settings{"pathBase"} = "/usr/local/aditl2010";
$settings{"urlBase"} = "http://aditl.mit.edu/2010/";

$settings{"templateLib"} = $settings{"pathBase"} . "/templates";
$settings{"logDirectory"} = $settings{"pathBase"} . "/logs";
$settings{"scratchDirectory"} = "/srv/aditl2010/scratch";
$settings{"incomingDir"} = "/srv/aditl2010/incoming";
$settings{"rootPhotoDir"} = "/srv/aditl2010/photoroot";
$settings{"tinyBarcodePath"} = "/srv/aditl2010/photoroot/tiny-barcodes";

$settings{"SMTPHost"} = "outgoing.mit.edu";

$settings{"aboutURL"} = $settings{"urlBase"} . "about";
$settings{"validateURL"} = $settings{"urlBase"} . "validate";
$settings{"registerURL"} = $settings{"urlBase"} . "register";
$settings{"phototestURL"} = $settings{"urlBase"} . "phototest";
$settings{"uploadURL"} = $settings{"urlBase"} . "upload";
$settings{"uploadrcvURL"} = $settings{"urlBase"} . "uploadrcv";
$settings{"loginURL"} = $settings{"urlBase"} . "login";
$settings{"photoURLBase"} = $settings{"urlBase"} . "photos";
$settings{"staticURLBase"} = $settings{"urlBase"} . "static";
$settings{"frontURL"} = $settings{"urlBase"} . "front";
$settings{"timelineURL"} = $settings{"urlBase"} . "timeline";
$settings{"htmlFragmentURL"} = $settings{"urlBase"} . "timeline-fragment.fcgi";
$settings{"jsFragmentURL"} = $settings{"urlBase"} . "js-fragment.fcgi";
$settings{"tinyBarcodeURL"} = $settings{"urlBase"} . "photos/tiny-barcodes";
$settings{"selectUserURL"} = $settings{"urlBase"} . "select-user";
$settings{"photoURL"} = $settings{"urlBase"} . "photo";


$settings{"friendLimit"} = 4;

$settings{"exiftagsCommand"} = "/usr/bin/exiftags -a";
$settings{"unzip"} = "/usr/bin/unzip";
$settings{"convert"} = "/usr/bin/convert";
$settings{"identify"} = "/usr/bin/identify";

$settings{"colorManipLightness"} = 200;
#$settings{"colorManipLightness"} = 240;
$settings{"colorManipSat"} = 225;
#$settings{"colorManipSat"} = 230;

$settings{"eventDate"} = "2010-09-23";

sub settings {
    my $setting = shift;
    if(exists($settings{$setting})) {
	return $settings{$setting};
    } else {
	die "$setting is not a valid setting\n";
    }
}




