# SRReport

SRReport is a small library which make easy for your testers to report bugs.
Shake the iDevice, and they will send:

* a screenshot of the current view
* the logs of the current session
* the crash report if a crash has been reported
* the dumped view hierarchy

# Installation

Add those frameworks to your target:

* QuartzCore
* MessageUI

Copy the `library` folder in your project.

Include `SRReporter.h`

Then, copy this line to start the reporter:

	- (BOOL)application:(UIApplication *)application 
			didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
   		[[SRReporter reporter] startListener]; //this line starts the reporter
   		return YES;
	}
	

# Usage

**Shake** the iDevice when you want to report something. A Mail Composer view will appear with all the information that will be send. The tester can add some explanation, and change the recipient of the email.