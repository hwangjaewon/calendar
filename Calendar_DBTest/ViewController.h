//
//  ViewController.h
//  Calendar_DBTest
//
//  Created by HWANG on 2015. 7. 15..
//  Copyright (c) 2015년 HWANG. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JTCalendar.h"
#import "JTCalendarDayView.h"

@interface ViewController : UIViewController<JTCalendarDataSource>

@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet JTCalendarContentView *calendarContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarContentViewHeight;

@property (strong, nonatomic) JTCalendar *calendar;
@end

