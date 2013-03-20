Manticore iOSViewFactory
========================

manticore-iosviewfactory is a view controller factory pattern for creating iOS applications.
Designed with a two-level hierachical view controller structure for a tabbed application. 
Inspired by intents on the Android platform.

Installation
------------

Install from CocoaPods using this repository.

Features
--------

Features included with this release:

* Two-level hierarchical view controller
* Intents to switch between views, similar to Android intents

Basic Usage
-----------

    #import "ManticoreViewFactory.h"

After the application has loaded, for example, in application:didFinishLaunchingWithOptions:

    // Some standard window setup

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    // Register views

    MCViewFactory *factory = [MCViewFactory sharedFactory];

    // the following two lines are optional. Built in views will show instead.
    [factory registerView:VIEW_BUILTIN_MAIN];  // comment this line out if you don't create MCMainViewController.xib and subclass MCMainViewController
    [factory registerView:VIEW_BUILTIN_ERROR]; // comment this line out if you don't create MCErrorViewController.xib and subclass MCErrorViewController
    [factory registerView:@"YourSectionViewController"];

    // Run the factory methods

    UIViewController* mainVC = [[MCViewFactory sharedFactory] createViewController:VIEW_BUILTIN_MAIN];
    [self.window setRootViewController:mainVC];
    [mainVC.view setFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];

    // Show the main view controller

    AppModelIntent* intent = [AppModelIntent intentWithSectionName:@"YourSectionViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];

    // ...

Sections and Views
------------------

### Section and view convention

Sections should correspond to a user interface's tabs and views should correspond to the pages
seens within a tab. Prefixes and suffixes are not included in the schema definition.

Sections can also be shown without any views if a single-level hierarchy, but to keep consistency
a single view should be created for that section.

### Views without the intent

Sometimes a developer wishes to show view controllers without using intents. In this case,
a dummy section should be created and subviews added inside. Then, the subviews are created
directly using:

    [[MCViewFactory sharedFactory] createViewController:@"MyViewController"]

Other Usage Notes
-----------------

All first-level view controllers should be suffixed with SectionViewController. Second-level view controllers can be registered and shown using the following snippets:

    [[MCViewFactory sharedFactory] registerView:@"YourViewController"];

    // ...

    AppModelIntent* intent = [AppModelIntent intentWithSectionName:@"YourSectionViewController" andViewName:@"YourViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];


Future work
-----------

The following features haven't been implemented:

* History stack for a back button
