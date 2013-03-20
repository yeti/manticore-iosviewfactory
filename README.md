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

Sections should correspond to a user interface's tabs and views should correspond to the pages
seens within a tab. Prefixes and suffixes are not included in the schema definition.

Sections can also be shown without any views if a single-level hierarchy, but to keep consistency
a single view should be created for that section.

### Two-Level Hierarchy

All first-level view controllers should be suffixed with SectionViewController. Second-level view controllers can be registered and shown using the following snippets:

    [[MCViewFactory sharedFactory] registerView:@"YourViewController"];

    // ...

    AppModelIntent* intent = [AppModelIntent intentWithSectionName:@"YourSectionViewController" andViewName:@"YourViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];

Intents and events
------------------

### Sending an intent

A view transition happens when a new intent is assigned to `setCurrentSection:`.

    AppModelIntent* intent = [AppModelIntent intentWithSectionName:@"YourSectionViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];

Valid animation styles include all valid UIViewAnimations and the following constants, listed below:

* UIViewAnimationOptionTransitionFlipFromLeft
* UIViewAnimationOptionTransitionFlipFromRight
* ANIMATION_NOTHING
* ANIMATION_PUSH
* ANIMATION_POP

Custom values can be assigned to the transition, which are sent to the receving view.

    AppModelIntent* intent = ...;
    [[intent savedInstanceState] setObject:@"someValue" forKey:@"yourKey"];
    [[intent savedInstanceState] setObject:@"anotherValue" forKey:@"anotherKey"];
    // ...
    [[MCViewModel sharedModel] setCurrentSection:intent];

### Receiving an event

The events `onResume:` and `onPause:` are called on each MCViewController and MCSectionViewController when the intent is fired. If the section stays the same and the view changes, both the section and view receive `onResume` and `onPause` events.

View factory
------------

Sometimes a developer wishes to show view controllers without using intents. In this case,
a dummy section should be created and subviews added inside. Then, the subviews are created
directly using:

    [[MCViewFactory sharedFactory] createViewController:@"MyViewController"]


History Stack
-------------

The history stack for a back button hasn't been implemented.
