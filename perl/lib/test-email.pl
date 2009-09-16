use strict;
use lib "./";
use Utils;


Utils::email("enobarber\@gmail.com", "reid\@tnq.mit.edu",
	     "hey there", "this is the body of the email"
	     );
