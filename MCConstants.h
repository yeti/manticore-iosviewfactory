//
//  MCConstants
//  Manticore iOSViewFactory
//
//  Created by Richard H Fung on July 1, 2013 (Canada Day).
//  Copyright (c) 2013. All rights reserved.
//

// special SECTION that goes to the previously seen section and view
#define SECTION_LAST  @"__MCLastViewController__"
#define SECTION_REWIND  @"__MCRewindViewController__"

// built in VIEWs that can be overriden by the user
#define VIEW_BUILTIN_ERROR @"MCErrorViewController"
#define VIEW_BUILTIN_MAIN @"MCMainViewController"

#define VIEW_BUILTIN_ERROR_NIB @"MCDefaultErrorViewController"
#define VIEW_BUILTIN_MAIN_NIB @"MCDefaultMainViewController"

// open space in UIViewAnimationOptions
// Bitwise left operator, why? Powers of two.......
#define ANIMATION_NOTHING     0 << 9
#define ANIMATION_PUSH        1 << 10
#define ANIMATION_POP         1 << 11
#define ANIMATION_POP_LEFT         1 << 14
#define ANIMATION_PUSH_LEFT        1 << 15


//exprimental
#define ANIMATION_SLIDE_FROM_BOTTOM   1 << 12
#define ANIMATION_SLIDE_FROM_TOP      1 << 13

static const int kAnimationPopToTop = 44;
static const int kAnimationPopToBottom = 45;


// iOS 5 support
#define MANTICORE_IOS5_SCREEN_SIZE 568
#define MANTICORE_IOS5_OVERLAY_SUFFIX @"_5"

// shared settings
#define MANTICORE_OVERLAY_ANIMATION_DURATION 0.5 // 200 ms

// stack size special values
#define STACK_SIZE_UNLIMITED 0
#define STACK_SIZE_DISABLED 1
