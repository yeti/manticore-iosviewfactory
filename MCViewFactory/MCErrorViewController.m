//
//  ErrorViewController.m
//  Manticore iOSViewFactory
//
//  Created by Anthony Scherba on 7/9/12.
//  Copyright (c) 2013 Yeti LLC. All rights reserved.
//

#import "MCErrorViewController.h"
#import "MCViewModel.h"

@implementation MCErrorViewController


-(id)init{
  if(self=[super init]){
    descripLabel.lineBreakMode = UILineBreakModeClip; //http://stackoverflow.com/questions/1054558/vertically-align-text-within-a-uilabel
  }
  return self;
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

-(void)loadLatestErrorMessage{
  NSDictionary *errorDict = [[MCViewModel sharedModel] errorDict];
  
  NSString *title = [errorDict objectForKey: @"title"];
  NSString *description = [errorDict objectForKey: @"description"];
  
  //RKRestKitError
  if ([errorDict objectForKey:@"error"]){
    NSError* error = [errorDict objectForKey:@"error"];
    NSArray* arrErrorCodes = [NSArray arrayWithObjects:@"Unknown error",
                              @"The app is experiencing a remote connection problem (91).", // RKObjectLoaderRemoteSystemError
                              @"The app is not connected to the Internet (92).", //RKRequestBaseURLOfflineError
                              @"The app is having trouble talking to the cloud (93).",// RKRequestUnexpectedResponseError
                              @"The app is having trouble talking to the cloud (94).",//RKObjectLoaderUnexpectedResponseError
                              @"The cloud is taking too much time to connect (95).",//RKRequestConnectionTimeoutError
                              nil];
    if ([error code] >= 0 && [error code] < [arrErrorCodes count]) {
      description = [arrErrorCodes objectAtIndex:[error code]];
    }
  }
  
  titleLabel.text = title;
  descripLabel.text =  [NSString stringWithFormat:@"%@\n\n\n\n\n\n\n\n\n\n\n\n\n\n",description];
}

-(IBAction) dismissError: (id) sender {
  [self.view removeFromSuperview];
}

-(IBAction) reportError:(id)sender{
//  TFLog(@"Error reported from %@: %@", titleLabel.text, descripLabel.text);
  
  [self.view removeFromSuperview];
  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Return YES for supported orientations
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
