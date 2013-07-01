Manticore iOS View Factory
==========================

*manticore-iosviewfactory* is a view controller factory pattern for creating iOS applications.
Designed with a two-level hierarchical view controller structure for a tabbed application. 
Inspired by [Android activity lifecycle](http://developer.android.com/training/basics/activity-lifecycle/pausing.html).

Installation
------------

Install from CocoaPods using this repository.

Early releases of Manticore iOS View Factory must be installed directly from this github repository:

    pod 'manticore-iosviewfactory', '~> 0.0.9', :git => 'https://github.com/YetiHQ/manticore-iosviewfactory.git'

Features
--------

Features included with this release:

* Two-level hierarchical view controller
* Intents to switch between activities, similar to Android intents

Basic Usage
-----------

    #import "ManticoreViewFactory.h"

After the application has loaded, for example, in `application:didFinishLaunchingWithOptions:`

    // Some standard window setup

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    // Register activities

    MCViewFactory *factory = [MCViewFactory sharedFactory];

    // the following two lines are optional. Built in activities will show instead.
    [factory registerView:VIEW_BUILTIN_MAIN];  // comment this line out if you don't create MCMainViewController.xib and subclass MCMainViewController
    [factory registerView:VIEW_BUILTIN_ERROR]; // comment this line out if you don't create MCErrorViewController.xib and subclass MCErrorViewController
    [factory registerView:@"YourSectionViewController"];

    // Run the factory methods

    UIViewController* mainVC = [[MCViewFactory sharedFactory] createViewController:VIEW_BUILTIN_MAIN];
    [self.window setRootViewController:mainVC];
    [mainVC.view setFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];

    // Show the main view controller

    MCIntent* intent = [MCIntent intentWithSectionName:@"YourSectionViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];

    // ...

Sections and Views
------------------

*Sections* should correspond to a user interface's tabs and *views* should correspond to the views inside a tab.
 Prefixes and suffixes are not included in the schema definition.

Sections can also be shown without views in order to create single-level hierarchy,
but it's a better design to create one section with multiple views.

NOTE: I haven't tested a single-level hierarchy with all sections and no views.

### Two-Level Hierarchy

All first-level view controllers should be suffixed with SectionViewController.
 Second-level view controllers can be registered and shown using the following snippets:

    [[MCViewFactory sharedFactory] registerView:@"YourViewController"];

    // ...

    MCIntent* intent = [MCIntent intentWithSectionName:@"YourSectionViewController" andViewName:@"YourViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];

Intents and events
------------------

### Sending an intent

A view transition happens when a new intent is assigned to `setCurrentSection:`.

    MCIntent* intent = [MCIntent intentWithSectionName:@"YourSectionViewController"];
    [intent setAnimationStyle:UIViewAnimationOptionTransitionFlipFromLeft];
    [[MCViewModel sharedModel] setCurrentSection:intent];

Valid animation styles include all valid UIViewAnimations and the following constants, listed below:

* `ANIMATION_NOTHING`
* `ANIMATION_PUSH`
* `ANIMATION_POP`
* `UIViewAnimationOptionTransitionFlipFromLeft`
* `UIViewAnimationOptionTransitionFlipFromRight`
* ...

`UIViewAnimation` run for 0.25 s and `ANIMATION_` run for 0.5 s. 


### Sending messages between activities

#### Sending

Custom instructions can be assigned for the receiving view's `onResume:`.

    MCIntent* intent = ...;
    [[intent savedInstanceState] setObject:@"someValue" forKey:@"yourKey"];
    [[intent savedInstanceState] setObject:@"anotherValue" forKey:@"anotherKey"];
    // ...
    [[MCViewModel sharedModel] setCurrentSection:intent];

#### Receiving

The events `onResume:` and `onPause:` are called on each MCViewController and MCSectionViewController
when the intent is fired. If the section stays the same and the view changes, both the section and
view receive `onResume` and `onPause` events.

When a view is restored, saved intent information can be loaded using:

    -(void)onResume:(MCIntent *)intent {
        NSObject* someValue = [intent.savedInstanceState objectForKey:@"yourKey"];
        NSObject* anotherValue = [intent.savedInstanceState objectForKey:@"anotherKey"];

        // ...

        // ensure the following line is called, especially for MCSectionViewController
        [super onResume:intent];
    }    

### View state

View controllers are cached on first load and reused throughout the application lifetime.
Application state should be loaded to `[intent savedInstanceState]` when `onResume:` is fired.
Modified view controller state should be saved `onPause:` when using the history stack.

The first time a view controller is loaded, `onCreate` is fired once for non-GUI setup. 
This event, however, is skipped if the view controller is loaded directly from MCViewFactory.

Cached view controllers can be flushed from memory with the following call:

    [[MCViewModel sharedModel] clearViewCache];

View factory
------------

Sometimes a developer wishes to show view controllers without using intents. In this case,
a dummy section should be created and subviews added inside. Then, the subviews are created
directly using:

    [[MCViewFactory sharedFactory] createViewController:@"MyViewController"]

`createViewController:` is a low-level function that does not provide caching, `onCreate`, 
`onResume`, and `onPause` events. This factory method can be used to load nested view controllers wherever and whenever you want.

History stack
-------------

A history stack for a back button can be configured:

* No history stack, i.e., no back button using:

    `[MCViewModel sharedModel].stackSize = STACK_SIZE_DISABLED;`

* Infinite history stack:

    `[MCViewModel sharedModel].stackSize = STACK_SIZE_UNLIMITED;`

* Bounded history stack, which is useful if you know beforehand how many views you can go:

    `[MCViewModel sharedModel].stackSize = 5; // 1 current + 4 history`


Fire an intent to navigate back in the history stack:

    if ([MCViewModel sharedModel].historyStack.count > 1){
        [MCViewModel sharedModel].currentSection = [MCIntent intentPreviousSectionWithAnimation:ANIMATION_POP];
    }

Or you can be more explicit by using `SECTION_LAST`:

    if ([MCViewModel sharedModel].historyStack.count > 1){
        [MCViewModel sharedModel].currentSection = [MCIntent intentWithSectionName:SECTION_LAST andAnimation:ANIMATION_POP];
    }

The history stack can be completely flushed before a new section is shown, which you want to do every once in a while to reduce memory consumption:

    [[MCViewModel sharedModel] clearHistoryStack];
    [[MCViewModel sharedModel] setCurrentSection:[MCIntent intentWithSectionName:...]];

Customizing the main window
---------------------------

The basic *MCMainViewController* shows a black window. If you want to override this window, for example, to show an application logo, you are able to do so:

1. Create `MCMainViewController.xib` file in XCode.
2. Have the `xib` File Owner be subclass `MCMainViewController`.
3. Connect the UIView to the File Owner's `view`.
4. When registering your views in code, add the following line:
    `[factory registerView:VIEW_BUILTIN_MAIN];`

Error dialog box
----------------

Manticore iOS View Factory comes with a built in error message view controller. To override the built in appearance and layout, 
create MCErrorViewController.xib and assign its file owner to subclass MCErrorViewController. 

Error messages are presented with a title label, message label, and button to dismiss the view controller. Error messages 
are not placed on the history stack, thus do not interfere with the navigation of your application.

### Showing error messages

To show error messages:

    [[MCViewModel sharedModel] setErrorTitle:@"Some Title" andDescription:"@Your message here"];

### Customizing the error window

The basic *MCErrorViewController* shows a grey window with a title, message body, and Dismiss button. If you want to override this window with your own look and feel:

1. Create `MCErrorViewController.xib` file in XCode.
2. Have the `xib` File Owner be a subclass of `MCErrorViewController`.
3. Connect the UIView to the File Owner's `view`.
4. Add a UILabel and connect it to `titleLabel`
5. Add a UILabel and connect it to `descripLabel`
6. Add a UIButton and set its *Touch Up Inside* to `dismissError:` action.
7. When registering your views in code, add the following line:
    `[factory registerView:VIEW_BUILTIN_ERROR];`

Screen overlays
---------------

Screen overlays are useful for giving instructions to the user. Screen overlays are implemented as UIImage resources embedded in the application. To show a screen overlay, call the following:

    [MCViewModel sharedModel].screenOverlay = @"some-image";

The string `@"some-image"` should be an image that is compatible with `[UIImage imageNamed:@"some-image"]`.

If the screen overlay is assigned several times, only the most recently overlay is shown.

### Displaying a sequence of overlays

Manticore iOS supports showing multiple screen overlays. When one overlay is dismissed, another overlay is shown until all of them are seen.

    [MCViewModel sharedModel].screenOverlays = @[@"image-1", @"image-2", @"image-3"];

### iPhone 4 and iPhone 5 overlays

Manticore iOS supports different overlays for iPhone 4 and iPhone 5. iPhone 5 overlays use the same name with a special suffix `_5`, which is added automatically. You should name your images as such:

* `some-image.png`
* `some-image_5.png`

Compiler settings
-----------------

Define `DEBUG` in compile settings to show debugger messages. `NSAssert` messages are unaffected by this setting.

Release notes
-------------

0.0.9: added helper intent for navigating to the previous screen

0.0.8: added screen overlays

0.0.7: solve a bug where fast switching between activities would cause all activities to disappear

0.0.6: debug messages are written to the console log to ensure `onPause:` and `onResume:` superclass are called

0.0.5: sections and views are properly resized and fitted to the parent

0.0.4: first stable release

Known issues
------------

* CocoaPods and .xib files: "A signed resource has been added, modified, or deleted" error for CocoaPods with .xib 
  files happens the second time when an app is run. 

  This issue has been documented:
  [https://github.com/CocoaPods/CocoaPods/issues/790](https://github.com/CocoaPods/CocoaPods/issues/790)

  Add the script `rm -rf ${BUILT_PRODUCTS_DIR}` to the Pre-actions of the Build stage of your application's Scheme.

* You'll implement `onResume` on a MCViewController but it doesn't get called. You probably overrode `onResume` on MCSectionViewController without calling `[super onResume:intent]`.
