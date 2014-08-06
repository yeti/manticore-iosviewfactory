/*
  MCIntent.h
  Manticore iOSViewFactory

  Created by Richard Fung on 9/19/12.
  Reworked, refactored and commented by Philippe Bertin on August 1, 2014
  Copyright (c) 2014 Yeti LLC. All rights reserved.

 
 ///////////////////////////////////////////////////////////////

 see the architecture design from Android:
 http://developer.android.com/reference/android/app/Activity.html

 ViewControllers are "activities" that receive bundles
 
 ///////////////////////////////////////////////////////////////
 
 
 How to use:

 1.  MCIntent* intent = [MCIntent intentWithSectionName:SECTION_?? viewName:VIEW_??]
     Create the intent object

 2. [[intent getSavedInstance] setObject:?? forKey:@"viewSpecificKey"]
     Assign any/all view-specific instructions. Read header files for definition.

 3. [[MCViewManager sharedManager] processIntent:intent];
     Load the section.
*/

#import <Foundation/Foundation.h>
#import "MCConstants.h"



@interface MCIntent : NSObject


/*! 
 * Getter for the intent's related section name
 */
@property (strong, nonatomic, readonly) NSString* sectionName;

/*!
 * Getter for the intent's related view name. 
 * @discussion Returns nil if no View is associated with the intent.
 */
@property (strong, nonatomic, readonly) NSString* viewName;

/*!
 * Getter fot the intent's savedInstanceState : the data associated with the intent.
 * @discussion As many objects as needed may be added to this dictionary : it will then be available when the intent's viewController is created, resumed and paused.
 * @discussion Be aware that this dictionary will take space in memory until this intent is flushed from the stack.
 */
@property (strong, nonatomic, readonly) NSMutableDictionary* savedInstanceState;

/*!
 * Getter and setter for this intent's animation style.
 * @discussion The animation style will be used to transition between the currentIntent and this intent.
 * @discussion Prefered animations are ANIMATION_NOTHING, ANIMATION_PUSH, ANIMATION_POP, UIViewAnimationOptionTransitionCrossDissolve. Other UI transitions work.
 * @discussion If no animationStyle is set, ANIMATION_NOTHING is the default.
 */
@property (readwrite) UIViewAnimationOptions animationStyle;


#pragma mark - Understanding Intents and How to Read the schemas

/* 
 *            **-----------**
 *            **  Intents  **
 *            **-----------**
 *
 *  Intents store information about are always related to a Section and should always be related to a View.
 *  An Intent contains :
 *          - sectionName   : the intent's related Section.
 *          - viewName      : the intent's related View -> the MCViewController that should be loaded when intent is processed
 *          - animationStyle: the animation style when switching from the current View to the Intent's View (-> when the intent is processed)
 *          - a dictionary  : the data you want to associate with the intent. In the View associated with the intent, you can use this dictionary to show the right data. Manticore call the functions "onCreate", "onResume" and "onPause" when displaying Views and provide the Intent so that you can retrieve the data from this Dictionary.
 
 *  However, this is true AFTER intents are processed.
 *  Before they are processed, intents can have two forms : 
 *      1. "Static" : when creating new intents (with the methods : "intentWith...")
 *      2. "Dynamic" (also named "navigation intent") : the intent contains a request for an already existing Intent in the history stack. It will contain all the elements in the above list AFTER it is processed.
 *
 *
 *            **---------------------------**
 *            **  HOW TO READ THE SCHEMAS  **
 *            **---------------------------**
 *
 *               +-- The Section (MCSectionViewController) the Intent is related to
 *               |       +-- A column represent an intent in the stack (with its related Section and View)
 *               |       |
 *               V       V
 * +--------+---- ----++---+---+---+---+---+---+---+---+---+---+-+-+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |\
 * | Stack  +---------||---+---+---+---+---+---+---+---+---+---+---| >- Latest intent
 * |        | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|/
 * +--------+---- ----++- -+---+---+---+---+---+---+---+---+---+- -+
 *               ^        \_ From oldest intent to the lastest _/
 *               |
 *               +-- The View (MCViewController) the Intent is related to
 *
 *
 *  "View (name)"       = (name of the) view-controller sub-classing MCViewController
 *                      = ViewVC in the schema : View11VC, View12VC, View21VC, etc.
 *
 *  "Section (name)"    = (name of the) view-controller sub-classing MCSectionViewController.
 *                      = SectionVC in schema  : Section1VC, Section2VC and Section3VC
 *
 *
 */



#pragma mark - New Intent creation methods


/*            **---------------------------------------**
 *            **  Schema for "intentWithSectionName:"  **
 *            **---------------------------------------**
 *
 *
 * Method used in example : "intentWithSectionName:Section3VC"
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+-+-+     +---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |     | 3 |
 * | Stack  +---------||---+---+---+---+---+---+---+---+---+---+---+ --> +---+
 * |        | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|     |   |
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+     +---+
 *
 */

/*!
 * @function intentWithSectionName
 * @discussion Sections without Views should be avoided.
 * @discussion Creates and return a new intent. This intent will not be related to any View, only a Section. Behavior has not been tested. 
 * @discussion Instead, we recommand creating a dummy MCSectionViewController sub-class and then create intents related to this Section for your Views that can not be grouped in Sections.
 * @param sectionName       The Section the intent will be related to
 */
+(id) intentWithSectionName: (NSString*) name;

/*!
 * @function intentWithSectionName
 * @discussion Only used by the undo operation.
 * @discussion Creates and return a new intent. This intent will not be related to any View, only a Section. Behavior has not been tested.
 * @discussion Instead, we recommand creating a dummy MCSectionViewController sub-class and then create intents related to this Section for your Views that can not be grouped in Sections.
 * @param sectionName       The Section the intent will be related to
 * @param andSavedInstance  The intent's savedInstance dictionary
 */
+(id) intentWithSectionName:(NSString*) name andSavedInstance:(NSMutableDictionary*) savedInstanceState;

/*!
 * @function intentWithSectionName
 * @discussion Creates and return a new intent. This intent will not be related to any View, only a Section. Behavior has not been tested.
 * @discussion Instead, we recommand creating a dummy MCSectionViewController sub-class and then create intents related to this Section for your Views that can not be grouped in Sections.
 * @param sectionName   The Section the intent will be related to
 * @param animation     The animation to this intent's View when processed.
 * @discussion Prefered animations are ANIMATION_NOTHING, ANIMATION_PUSH, ANIMATION_POP, UIViewAnimationOptionTransitionCrossDissolve. Other UI transitions work.
 */
+(id) intentWithSectionName: (NSString*) name andAnimation:(UIViewAnimationOptions) animation;




/*            **----------------------------------------------------**
 *            **  Schema for "intentWithSectionName: andViewName:"  **
 *            **----------------------------------------------------**
 *
 *
 * Input in example : "intentWithSectionName:Section3VC andViewName:View35VC"
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+-+-+     +---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |     | 3 |
 * | Stack  |---------||---+---+---+---+---+---+---+---+---+---+---+ --> +---+
 * |        | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|     | 35|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+     +---+
 *
 */

/*!
 * @function intentWithSectionName andViewName
 * @discussion Creates and return a new intent related to a Section and a View.
 * @param sectionName   The Section the intent will be related to
 * @param viewName      The View that will be managed by this instance
 */
+(id) intentWithSectionName: (NSString*) sectionName andViewName: (NSString*) viewName;

/*!
 * @function intentWithSectionName andViewName
 * @discussion Creates and return a new intent related to a Section and a View and with an animation.
 * @param sectionName   The Section the intent will be related to
 * @param viewName      The View that will be managed by this instance
 * @param animation     The animation to this intent's View when processed. 
 * @discussion Prefered animations are ANIMATION_NOTHING, ANIMATION_PUSH, ANIMATION_POP, UIViewAnimationOptionTransitionCrossDissolve. Other UI transitions work.
 */
+(id) intentWithSectionName:(NSString*)sectionName viewName:(NSString*)viewName andAnimation:(UIViewAnimationOptions)animation;




#pragma mark - Navigation Intents

#pragma mark - Push methods


/*            **-------------------------------------**
 *            **  Schema for "pushIntentFromHistory" **
 *            **-------------------------------------**
 *
 * Inputs in example :
 *    - pushIntentFromHistoryByPosition: 6
 * or - pushIntentFromHistoryByName: @"View22VC"
 *
 *                                       +---------------------------+
 *                                       |                           |
 * +--------+---------++---+---+---+---+-+-+---+---+---+---+---+---+ |
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 | |
 * | Stack  |---------||---+---+---+---+---+---+---+---+---+---+---+ |
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33| |
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+ |
 *    |                                                          |   |
 *    |                            intent position 0 in stack ---+   |
 *    v                                                              v
 * +--------+---------++---+---+---+---X---X---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 |XXX| 1 | 1 | 3 | 3 | 3 | 3 | 2 |
 * | Stack  |---------||---+---+---+---+-X-+---+---+---+---+---+---+---+
 * |        | ViewVC  || 11| 12| 13| 21|XXX| 21| 12| 31| 32| 34| 33| 22|
 * +--------+---------++---+---+---+---X---X---+---+---+---+---+---+---+
 *    |
 *    v
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 1 | 1 | 3 | 3 | 3 | 3 | 2 |
 * | Stack  |---------||---+---+---+---+---+---+---+---+---+---+---+
 * | after  | ViewVC  || 11| 12| 13| 21| 21| 12| 31| 32| 34| 33| 22|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 *                                                               |
 *                                 intent position 0 in stack ---+
 */

/*!
 * @function pushIntentFromHistory
 * Push a specific intent from the history stack to the top of the stack.
 * @discussion Push means that when found, the intent will be removed from its position in the stack and placed on top of the stack.
 * @param ptrIntent Pointer to the intent to push on top of the stack.
 */
+(MCIntent *) pushIntentFromHistory: (MCIntent *) ptrToIntent;

/*!
 * @function pushIntentFromHistoryByPosition
 * Push an intent to the top of the stack, given its position in the stack.
 * @discussion Push means that when found, the intent will be removed from its position in the stack and placed on top of the stack.
 * @param positionInStack Intent's position in the stack. Position 1 = last intent in the history stack. Has to be > 0.
 */
+(MCIntent *) pushIntentFromHistoryByPosition: (int) positionInStack;

/*!
 * @function pushIntentFromHistoryByName
 * Push an intent to the top of the stack, given it's associated View's name.
 * @discussion Push means that when found, the intent will be removed from its position in the stack and placed on top of the stack.
 * @discussion /!\ WARNING /!\ Because multiple intents might have the same name, this method will find the first intent matching the given name in the history stack and push it on top of the stack.
 * @param mcViewControllerName Name of the MCViewController (View) associated with the intent to find.
 */
+(MCIntent *) pushIntentFromHistoryByName: (NSString *) mcViewControllerName;




#pragma mark - Pop methods

#pragma mark Pop to an intent in History

/*            **-------------------------------------**
 *            **  Schema for "popToIntentInHistory"  **
 *            **-------------------------------------**
 *
 * Method used in example :
 *       - popToIntentInHistory: 6
 *   or  - popToIntentInHistory: @"View22VC"
 *
 *                                       |
 *                                       v
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||---+---+---+---+---+---+---+---+---+---+---|
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 |
 * | Stack  |---------||---+---+---+---+---|
 * | after  | ViewVC  || 11| 12| 13| 21| 22|
 * +--------+---------++---+---+---+---+---+
 *                                       |
 *         intent position 0 in stack ---+
 *
 *
 */

/*!
 * @function popToIntentInHistory
 * Pop to a specific intent in the history stack.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for.
 * @param ptrIntent Pointer to the intent to pop to.
 */
+(MCIntent *) popToIntentInHistory: (MCIntent *) ptrToIntent;

/*!
 * @function popToIntentInHistoryByPosition
 * Pop to an intent given its position in the stack.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for.
 * @param positionInStack Intent's position in the stack. Position 1 = last intent in the history stack. Has to be > 0.
 */
+(MCIntent *) popToIntentInHistoryByPosition: (int) positionInStack;

/*!
 * @function popToIntentInHistoryByPositionLast
 * Pop to the last intent in the history stack.
 * @discussion Same as using popToIntentInHistoryByPosition:1
 */
+(MCIntent *) popToIntentInHistoryByPositionLast;

/*!
 * @function popToIntentInHistoryByName
 * Pop to an intent, given it's associated View's name.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for.
 * @discussion /!\ WARNING /!\ Because multiple intents might have the same name, this method will find the first intent matching the given name in the history stack and pop to it.
 * @param mcViewControllerName Name of the MCViewController (View) associated with the intent to find.
 */
+(MCIntent *) popToIntentInHistoryByName: (NSString *) mcViewControllerName;




#pragma mark Pop to Sections' Root intents


/*            **--------------------------------**
 *            **  Schema for "popToIntentRoot"  **
 *            **--------------------------------**
 *
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||---+---+---+---+---+---+---+---+---+---+---|
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+
 * |        |SectionVC|| 1 |
 * | Stack  |---------||---|
 * | after  | ViewVC  || 11|
 * +--------+---------++- -+
 *                       |
 * intent position 0  ---+
 *
 *
 * Infos : root section is Section1VC and the root View in this section is View11VC.
 *
 */

/*!
 * @function popToIntentRoot
 * Pop to the root intent in the history stack.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for (the root intent here).
 */
+(MCIntent *) popToIntentRoot;




/*            **------------------------------------------------**
 *            **  Schema for "popToIntentRootInSectionCurrent"  **
 *            **------------------------------------------------**
 *
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||-------------------------------------------+
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 |
 * | Stack  |---------||-------------------+------------
 * | after  | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31|
 * +--------+---------++---+---+---+---+---+---+---+---+
 *                                                   |
 *                     intent position 0 in stack ---+
 *
 * Infos : current section is Section3VC and the root View in this section is View31VC.
 *
 */

/*!
 * @function popToIntentRootInSectionCurrent
 * Pop to the root intent of the current section in the history stack.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for (the root intent of the current section here).
 */
+(MCIntent *) popToIntentRootInSectionCurrent;




/*            **---------------------------------------------**
 *            **  Schema for "popToIntentRootInSectionLast"  **
 *            **---------------------------------------------**
 *
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||-------------------------------------------+
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 |
 * | Stack  |---------||-------------------+----
 * | after  | ViewVC  || 11| 12| 13| 21| 22| 21|
 * +--------+---------++---+---+---+---+---+- -+
 *                                           |
 *             intent position 0 in stack ---+
 *
 *
 * Infos : last section is Section1VC and the root View in this section is View21VC.
 */

/*!
 * @function popToIntentRootInSectionLast
 * Pop to the root intent of the last section in the history stack.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for (the root intent of the last section here).
 */
+(MCIntent *) popToIntentRootInSectionLast;




/*            **----------------------------------------------**
 *            **  Schema for "popToIntentRootInSectionNamed"  **
 *            **----------------------------------------------**
 *
 *  Method used in example : "popToIntentRootInSectionNamed:@"Section1VC"
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||-------------------------------------------+
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 |
 * | Stack  |---------||-------------------+----
 * | after  | ViewVC  || 11| 12| 13| 21| 22| 21|
 * +--------+---------++---+---+---+---+---+- -+
 *                                           |
 *             intent position 0 in stack ---+
 *
 *
 * Infos : first occurence of Section1VC in the stack is in position 4, then root view in section is View21VC
 * Warning : As you can see, Section1 appears again later in the stack, 
 *      but because there is another Section in between (Section2), it won't go there.
 */

/*!
 * @function popToIntentRootInSectionNamed
 * Pop to the root intent of the section with the given name.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for (the root intent of the given section).
 * /!\ WARNING /!\ This method will find the first intent in the stack that is related to the given Section name and then find the root in the Section. If the Section appears again previously in the stack, it will not be reached. See header comments for a visual representation of this warning.
 * @param mcSectionViewControllerName Name of the MCSectionViewController (Section) associated with the intent to find.
 */
+(MCIntent *) popToIntentRootInSectionNamed: (NSString *) mcSectionViewControllerName;




#pragma mark Pop to Sections' last intents



/*            **---------------------------------------------**
 *            **  Schema for "popToIntentLastInSectionLast"  **
 *            **---------------------------------------------**
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||-------------------------------------------+
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 |
 * | Stack  |---------||-------------------+----
 * | after  | ViewVC  || 11| 12| 13| 21| 22| 21|
 * +--------+---------++---+---+---+---+---+- -+
 *                                           |
 *             intent position 0 in stack ---+
 *
 *
 * Infos : SectionLast is Section1VC. Inside this section, IntentLast is the last encountered intent : the one pointing to View12VC.
 */

/*!
 * @function popToIntentLastInSectionLast
 * Pop to the root intent of the current section in the history stack.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for (the root intent of the current section).
 */
+(MCIntent *) popToIntentLastInSectionLast;




/*            **----------------------------------------------**
 *            **  Schema for "popToIntentLastInSectionNamed"  **
 *            **----------------------------------------------**
 *
 * Method used in example : "popToIntentLastInSectionNamed:@"Section1VC"
 *
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 | 3 | 3 | 3 | 3 |
 * | Stack  |---------||-------------------------------------------+
 * | before | ViewVC  || 11| 12| 13| 21| 22| 21| 12| 31| 32| 34| 33|
 * +--------+---------++---+---+---+---+---+---+---+---+---+---+- -+
 *                                                               |
 *                                 intent position 0 in stack ---+
 *
 * +--------+---------++---+---+---+---+---+---+---+
 * |        |SectionVC|| 1 | 1 | 1 | 2 | 2 | 1 | 1 |
 * | Stack  |---------||-------------------+---+---|
 * | after  | ViewVC  || 11| 12| 13| 21| 22| 21| 12|
 * +--------+---------++---+---+---+---+---+---+- -+
 *                                               |
 *                 intent position 0 in stack ---+
 *
 *
 * Infos : first occurence of Section named "Section1VC" in the stack is in position 4, which is also the position of the IntentLast (always).
 * Warning : As you can see, Section1 appears again later in the stack,
 *      but because there is another Section in between (Section2), it won't go there.
 */

/*!
 * @function popToIntentLastInSectionNamed
 * Pop to the last intent (first encountered intent when rewinding the stack) of the section with the given name.
 * @discussion Pop means removing one by one each intent in the history stack until finding the one it is looking for.
 * /!\ WARNING /!\ This method will find the first intent in the stack that is related to the given Section name. If the Section appears again previously in the stack, it will not be reached. See header comments for a visual representation of this warning.
 * @param mcSectionViewControllerName Name of the MCSectionViewController (Section) associated with the intent to find.
 */
+(MCIntent *) popToIntentLastInSectionNamed: (NSString *) mcSectionViewControllerName;



#pragma mark - Depreciated methods


// intent for going to the last view, no animation
+(id) intentPreviousIntent __deprecated;

// intent for going to the last view, any animation
+(id) intentPreviousIntentWithAnimation:(UIViewAnimationOptions)animation __deprecated;

// intent for going to a specific view in the history stack
+(id) intentToLoadHistoricalIntentNumber: (NSNumber *) historyNum __deprecated;


@end
