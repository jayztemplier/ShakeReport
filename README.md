# SRReport

<!-- MacBuildServer Install Button -->
<div class="macbuildserver-block">
    <a class="macbuildserver-button" href="http://macbuildserver.com/project/github/build/?xcode_project=ShakeReport.xcodeproj&amp;target=ShakeReport&amp;repo_url=git%3A%2F%2Fgithub.com%2Fjayztemplier%2FShakeReport.git&amp;build_conf=Release" target="_blank"><img src="http://com.macbuildserver.github.s3-website-us-east-1.amazonaws.com/button_up.png"/></a><br/><sup><a href="http://macbuildserver.com/github/opensource/" target="_blank">by MacBuildServer</a></sup>
</div>
<!-- MacBuildServer Install Button -->

SRReport is a small library which make easy for your testers to report bugs.
Shake the iDevice, and they will send:

* a screenshot of the current view
* the logs of the current session
* the crash report if a crash has been reported
* the dumped view hierarchy

<a href="http://shakereport.com/">Go to our website to get more information</a>

# Installation

If you use Cocoapods, add the `ShakeReport` pod to your `Podfile`.

OR

Add those frameworks to your target:

* QuartzCore
* MessageUI
* CoreVideo
* CoreMedia
* AVFoundation
* AssetsLibrary

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

# Configurations
### Without Screen Capture
You can setup the default email address that should receive the reports:

	SRReporter *reporter = [SRReporter reporter];
    [reporter setDefaultEmailAddress:@"templier.jeremy@gmail.com"];
    [reporter startListener];

### With Screen Capture
You basically have 2 options. The first one is to record the entire session:
    #include "SRVideoReporter.h"
    
    SRVideoReporter *reporter = [SRVideoReporter reporter];
    NSURL *url = [NSURL URLWithString:@"http://localhost:3000"];
    [reporter setUsername:@"jayztemplier"];
    [reporter setPassword:@"mypassword"];
    [reporter startListenerConnectedToBackendURL:url];
    [reporter startScreenRecorder];

But be careful, the entire video will be recorded on the user's device. That's why we recommend you to set a max duration for the video. To do so, you just have to replace the last line of the previous example by:

    // replace [reporter startScreenRecorder]; by
    [reporter startScreenRecorderWithMaxDurationPerVideo:30]; //max duration = 30 sec

# Additional Information
If you need to add custom information to the reports sent by email, you can do it!

    [reporter setCustomInformationBlock:^NSString *{
        return [NSString stringWithFormat:@"Application: Sample Application, User: Jayztemplier, Device Name: %@", [[UIDevice currentDevice] name]];
    }];

The block has to return a string which will be inserted in the additionalInformation.log file.

# Use it with a Backend
You can also use Shake Report with a backend. And guess what!? It's open source too!
https://github.com/jayztemplier/ShakeReportServer

To send the reports to the server, setup the listener like that:
	
    SRReporter *reporter = [SRReporter reporter];
    // Send data to a Server instead of displaying the mail composer
    NSURL *url = [NSURL URLWithString:@"http://localhost:3000/reports.json"];
    [reporter startListenerConnectedToBackendURL:url];

If you backend is protected with a username and a password, you have to setup the reporter:

	[reporter setUsername:@"jayztemplier"];
	[reporter setPassword:@"mypassword"];

# License
SRReport is available under the MIT license. See the LICENSE file for more info