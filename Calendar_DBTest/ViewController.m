//
//  ViewController.m
//  Calendar_DBTest
//
//  Created by HWANG on 2015. 7. 15..
//  Copyright (c) 2015년 HWANG. All rights reserved.
//

#import "ViewController.h"
#import "JTCalendar.h"
#import "DBInterface.h"

@interface ViewController ()
{
    NSMutableDictionary *eventsByDate;
    
    IBOutlet UIView *addScheduleUIView;
    IBOutlet UITextField *addSchedule;
    IBOutlet UITextView *addSchedule2;
    IBOutlet UIButton *addBtn;
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *bodyLabel;
    NSString *parameter1;
    NSString *parameter2;

    IBOutlet UIView *DeleteView;
    IBOutlet UIButton *EditBtn;
}
@end

@implementation ViewController
NSString *date_cutting;
NSRange range = {0,10};

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.calendar = [JTCalendar new];
    
    // All modifications on calendarAppearance have to be done before setMenuMonthsView and setContentView
    // Or you will have to call reloadAppearance
    {
        self.calendar.calendarAppearance.calendar.firstWeekday = 2; // Sunday == 1, Saturday == 7
        self.calendar.calendarAppearance.dayCircleRatio = 9. / 10.;
        self.calendar.calendarAppearance.ratioContentMenu = 2.;
        self.calendar.calendarAppearance.focusSelectedDayChangeMode = YES;
        
        // Customize the text for each month
        self.calendar.calendarAppearance.monthBlock = ^NSString *(NSDate *date, JTCalendar *jt_calendar){
            NSCalendar *calendar = jt_calendar.calendarAppearance.calendar;
            NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date];
            NSInteger currentMonthIndex = comps.month;
            
            static NSDateFormatter *dateFormatter;
            if(!dateFormatter){
                dateFormatter = [NSDateFormatter new];
                dateFormatter.timeZone = jt_calendar.calendarAppearance.calendar.timeZone;
            }
            
            while(currentMonthIndex <= 0){
                currentMonthIndex += 12;
            }
            
            NSString *monthText = [[dateFormatter standaloneMonthSymbols][currentMonthIndex - 1] capitalizedString];
            
            return [NSString stringWithFormat:@"%ld\n%@", comps.year, monthText];
        };
    }
    
    [self.calendar setMenuMonthsView:self.calendarMenuView];
    [self.calendar setContentView:self.calendarContentView];
    [self.calendar setDataSource:self];
    [self createRandomEvents];
    
    [addSchedule2.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
    [addSchedule2.layer setBorderWidth:2.0];
    
    //The rounded corner part, where you specify your view's corner radius:
    addSchedule2.layer.cornerRadius = 5;
    addSchedule2.clipsToBounds = YES;
    addScheduleUIView.layer.cornerRadius = 5;
    addScheduleUIView.clipsToBounds = YES;
   
    [self.calendar reloadData];
}

- (void)viewDidLayoutSubviews
{
    [self.calendar repositionViews];
}

-(void)viewWillAppear:(BOOL)animated
{
    addScheduleUIView.hidden = YES;
    DeleteView.hidden = YES;
}
#pragma mark - Buttons callback

- (IBAction)didGoTodayTouch
{
    [self.calendar setCurrentDate:[NSDate date]];
}

- (IBAction)didChangeModeTouch
{
    self.calendar.calendarAppearance.isWeekMode = !self.calendar.calendarAppearance.isWeekMode;
    
    [self transitionExample];
}

#pragma mark - JTCalendarDataSource

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date
{
    NSString *key = [[self dateFormatter] stringFromDate:date];
    if(eventsByDate[key] && [eventsByDate[key] count] > 0){
        return YES;
    }
    
    return NO;
}

//데이트 클릭 이벤트
- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date
{
    addSchedule.text=@"";
    addSchedule2.text=@"";
    addScheduleUIView.hidden = NO;
    
    NSString *key = [[self dateFormatter] stringFromDate:date];
    NSArray *events = eventsByDate[key];
    NSLog(@"Date: %@ - %ld events", date, [events count]);
    
    date_cutting  = [[self dateFormatter] stringFromDate:date];
}

//데이트 롱클릭 이벤트
- (void)calendarDidDateLongClickSelected:(JTCalendar *)calendar date:(NSDate *)date title:(NSString *)title body:(NSString *)body
{
    date_cutting  = [[self dateFormatter] stringFromDate:date];
    
    NSString *message1 = [@"일정 " stringByAppendingString:title];
    NSString *message2 = [[message1 stringByAppendingString:@"\n내용: "] stringByAppendingString:body];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:date_cutting message:message2 delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"삭제",@"수정",nil];
    parameter1 = title;
    parameter2 = body;
    [alertView show];
}

//데이터 삭제 수정
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"1. buttonindex is %ld", (long)buttonIndex);
    
    if (buttonIndex == 1) {//삭제
        NSLog(@"1 delete long click");
        DeleteView.hidden = NO;
    }
    else if (buttonIndex == 2) {//수정
        addScheduleUIView.hidden = NO;
        addSchedule.text = parameter1; //title
        addSchedule2.text= parameter2; //body
    }
}


- (IBAction)pressedDeleteBtn:(id)sender {
    NSLog(@"2 pressDeleteBtn");
    [[DBInterface sharedDB] openDB];
    [[DBInterface sharedDB] deleteRecord:parameter1];
    DeleteView.hidden = YES;
    [self.calendar reloadData];
}

- (IBAction)EditBtn:(id)sender {
    NSString *title = addSchedule.text;
    NSString *body = addSchedule2.text;
    
    [[DBInterface sharedDB] openDB];
    [[DBInterface sharedDB] createTableNamed:@"memo" withField1:@"title" withField2:@"body"];
    [[DBInterface sharedDB] updateRecord:@"memo" title:title body:body original_title:parameter1];
    
    addScheduleUIView.hidden = YES;
    [self.calendar reloadData];
}

- (IBAction)pressedAddBtn:(id)sender {
        NSString *title = addSchedule.text;
        NSString *body = addSchedule2.text;
    
    
        NSString *dateCut = [date_cutting substringWithRange:range];
        NSLog(@"date %@", dateCut);
    
        //add
        [[DBInterface sharedDB] openDB];
        [[DBInterface sharedDB] createTableNamed:@"memo" withField1:@"title" withField2:@"body"];
        [[DBInterface sharedDB] insertRecord:@"memo" title:title body:body date:dateCut];
    
        addScheduleUIView.hidden = YES;
        [self.calendar reloadData];
}

- (void)calendarDidLoadPreviousPage
{
    NSLog(@"Previous page loaded");
}

- (void)calendarDidLoadNextPage
{
    NSLog(@"Next page loaded");
}

#pragma mark - Transition examples

- (void)transitionExample
{
    CGFloat newHeight = 300;
    if(self.calendar.calendarAppearance.isWeekMode){
        newHeight = 75.;
    }
    
    [UIView animateWithDuration:.5
                     animations:^{
                         self.calendarContentViewHeight.constant = newHeight;
                         [self.view layoutIfNeeded];
                     }];
    
    [UIView animateWithDuration:.25
                     animations:^{
                         self.calendarContentView.layer.opacity = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.calendar reloadAppearance];
                         
                         [UIView animateWithDuration:.25
                                          animations:^{
                                              self.calendarContentView.layer.opacity = 1;
                                          }];
                     }];
}

#pragma mark - Fake data

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"dd-MM-yyyy";
    }
    
    return dateFormatter;
}

- (void)createRandomEvents
{
    eventsByDate = [NSMutableDictionary new];
    
    for(int i = 0; i < 30; ++i){
        // Generate 30 random dates between now and 60 days later
        NSDate *randomDate = [NSDate dateWithTimeInterval:(rand() % (3600 * 24 * 60)) sinceDate:[NSDate date]];
        
        // Use the date as key for eventsByDate
        NSString *key = [[self dateFormatter] stringFromDate:randomDate];
        
        if(!eventsByDate[key]){
            eventsByDate[key] = [NSMutableArray new];
        }
        
        [eventsByDate[key] addObject:randomDate];
    }
}

#pragma mark - Keyboard
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

@end
