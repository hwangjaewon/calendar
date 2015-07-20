//
//  JTCalendarDayView.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendarDayView.h"
#import "JTCircleView.h"
#import "DBInterface.h"
#import "JTCalendar.h"

@interface JTCalendarDayView (){
    UIView *backgroundView;
    UILabel *textLabel;
    UILabel *textLabel2;
    UITextView *detailSchedules;
    
    JTCircleView *circleView;
//    JTCircleView *dotView;
    
    BOOL isSelected;
    int cacheIsToday;
    NSString *cacheCurrentDateText;
    NSArray *holidayArray;
    NSArray *holidayArrayName;
    NSMutableArray *totalDateIncludingLuna;
    NSMutableArray *totalDateIncludingLunaName;
    
    NSMutableArray *cumulative_titles;
    NSMutableArray *total_date;
    NSMutableArray *total_title;
    NSMutableArray *total_doby;
    
}
@end

static NSString *const kJTCalendarDaySelected = @"kJTCalendarDaySelected";

@implementation JTCalendarDayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    //여기다가 넣는 게 아닌 것 같다!! 여러 번 호출되니까... init 한 번만 호출하는 함수를 못 찾겠다!
    [self commonInit];
    holidayArray = [NSArray new];
    holidayArrayName = [NSArray new];
    totalDateIncludingLuna = [NSMutableArray new];
    totalDateIncludingLunaName = [NSMutableArray new];
    cumulative_titles = [NSMutableArray new];
    total_date = [NSMutableArray new];
    total_title = [NSMutableArray new];
    total_doby = [NSMutableArray new];
    
    totalDateIncludingLuna = [[NSMutableArray alloc] init];
    totalDateIncludingLunaName = [[NSMutableArray alloc] init];
    cumulative_titles = [[NSMutableArray alloc] init];
    total_date = [[NSMutableArray alloc] init];
    total_title = [[NSMutableArray alloc] init];
    total_doby = [[NSMutableArray alloc] init];
    
    holidayArray = [[NSArray alloc] initWithObjects: @"01-01", @"03-01", @"05-05", @"06-06",@"08-15", @"10-03", @"10-09", @"12-25", nil];
    holidayArrayName = [[NSArray alloc] initWithObjects: @"신정", @"삼일절", @"어린이날", @"현충일",@"광복절", @"개천절", @"한글날", @"크리스마스", nil];
    
    [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
}

- (void)commonInit
{
    isSelected = NO;
    self.isOtherMonth = NO;

    {
        backgroundView = [UIView new];
        [self addSubview:backgroundView];
    }
    
    {
        circleView = [JTCircleView new];
        [self addSubview:circleView];
    }
    
    {
        textLabel = [UILabel new];
        [self addSubview:textLabel];
        textLabel2 = [UILabel new];
        [self addSubview:textLabel2];
        detailSchedules = [UITextView new];
        [self addSubview:detailSchedules];
    }
    
    {
//        dotView = [JTCircleView new];
//        [self addSubview:dotView];
//        dotView.hidden = YES;
    }
    
    {
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouch)];
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestures)]; //롱클릭으로 일정 수정,삭제 노출
        
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:gesture];
        [self addGestureRecognizer:lpgr];
    }
    
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDaySelected:) name:kJTCalendarDaySelected object:nil];
    }
}

- (void)layoutSubviews
{
    [self configureConstraintsForSubviews];
    
    // No need to call [super layoutSubviews]
}

// Avoid to calcul constraints (very expensive)
- (void)configureConstraintsForSubviews
{
    textLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    textLabel2.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height+37);
    textLabel2.textAlignment = NSTextAlignmentCenter;
    textLabel2.font = [UIFont systemFontOfSize:9];
    textLabel2.textColor = [UIColor blackColor];
    
    
    
//    CGFloat sizeCircle = MIN(self.frame.size.width, self.frame.size.height);
    CGFloat sizeCircle = MIN(self.frame.size.width-10, self.frame.size.height-10);
//    CGFloat sizeDot = sizeCircle;
    
    sizeCircle = sizeCircle * self.calendarManager.calendarAppearance.dayCircleRatio;
//    sizeDot = sizeDot * self.calendarManager.calendarAppearance.dayDotRatio;
    
    sizeCircle = roundf(sizeCircle);
//    sizeDot = roundf(sizeDot);
    
    circleView.frame = CGRectMake(0, 0, sizeCircle, sizeCircle);
    circleView.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    circleView.layer.cornerRadius = sizeCircle / 2.;
    
//    dotView.frame = CGRectMake(0, 0, sizeDot, sizeDot);
//    dotView.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) +sizeDot * 2.5);
//    dotView.layer.cornerRadius = sizeDot / 2.;
}

- (void)setDate:(NSDate *)date
{
    textLabel2.text = @""; //아닐경우 해당 자리에 계속 나오게 된다.
    
    
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:self.calendarManager.calendarAppearance.dayFormat];
    }
    
    self->_date = date;
    
    //표시할 날짜 01, 02 ..
    textLabel.text = [dateFormatter stringFromDate:date];
    cacheIsToday = -1;
    cacheCurrentDateText = nil;
}

//롱클릭
- (void)handleLongPressGestures
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    }
    
    NSString *personalDay = [dateFormatter stringFromDate:self.date];
    NSString *title;
    NSString *body;
    
    //개인스케쥴 정보 있으면 가져오기
    for(int i=0; i < [total_date count] ; i++)
    {
        if([personalDay isEqualToString:[total_date objectAtIndex:i]] )
        {
            title = [total_title objectAtIndex:i];
            body = [total_doby objectAtIndex:i];
            
            //View Controller의 함수로 이동 - 롱클릭 함수
            [self.calendarManager.dataSource calendarDidDateLongClickSelected:self.calendarManager date:self.date title:title body:body];
        }
    }
    
    //select all from DB - 주기적으로 정보를 바꿔줘야 새 정보를 가져올 수 있음
    [[DBInterface sharedDB] openDB];
    //            [[DBInterface sharedDB] deleteRecord:@""];
    cumulative_titles = [[DBInterface sharedDB] getTitleRowsFromTbleNamed];
    
    for(int i = 0 ; i< [cumulative_titles count]; i++)
    {
        total_date[i] = [cumulative_titles[i] objectForKey:@"date"];
        total_title[i] = [cumulative_titles[i] objectForKey:@"title"];
        total_doby[i] = [cumulative_titles[i] objectForKey:@"body"];
    }
    
}


- (void)didTouch
{
    if([self.calendarManager.dataSource respondsToSelector:@selector(calendar:canSelectDate:)]){
        if(![self.calendarManager.dataSource calendar:self.calendarManager canSelectDate:self.date]){
            return;
        }
    }
    
    [self setSelected:YES animated:YES];
    [self.calendarManager setCurrentDateSelected:self.date];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJTCalendarDaySelected object:self.date];
    
    [self.calendarManager.dataSource calendarDidDateSelected:self.calendarManager date:self.date];
    
    if(!self.isOtherMonth || !self.calendarManager.calendarAppearance.autoChangeMonth){
        return;
    }
    
    NSInteger currentMonthIndex = [self monthIndexForDate:self.date];
    NSInteger calendarMonthIndex = [self monthIndexForDate:self.calendarManager.currentDate];
        
    currentMonthIndex = currentMonthIndex % 12;
    
    if(currentMonthIndex == (calendarMonthIndex + 1) % 12){
        [self.calendarManager loadNextPage];
    }
    else if(currentMonthIndex == (calendarMonthIndex + 12 - 1) % 12){
        [self.calendarManager loadPreviousPage];
    }
}

- (void)didDaySelected:(NSNotification *)notification
{
    NSDate *dateSelected = [notification object];
    
    if([self isSameDate:dateSelected]){
        if(!isSelected){
            [self setSelected:YES animated:YES];
        }
    }
    else if(isSelected){
        [self setSelected:NO animated:YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if(isSelected == selected){
        animated = NO;
    }
    
    isSelected = selected;
    
    circleView.transform = CGAffineTransformIdentity;
    CGAffineTransform tr = CGAffineTransformIdentity;
    CGFloat opacity = 1.;
    
    if(selected){
        if(!self.isOtherMonth){
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorSelected];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorSelected];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorSelected];
        }
        else{
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorSelectedOtherMonth];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorSelectedOtherMonth];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorSelectedOtherMonth];
        }
        
        circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
        tr = CGAffineTransformIdentity;
    }
    else if([self isToday]){
        if(!self.isOtherMonth){
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorToday];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorToday];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorToday];
        }
        else{
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorTodayOtherMonth];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorTodayOtherMonth];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorTodayOtherMonth];
        }
    }
    else{
        if(!self.isOtherMonth){
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColor];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColor];
        }
        else{
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorOtherMonth];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorOtherMonth];
        }
        
        opacity = 0.;
    }
    
    if(animated){
        [UIView animateWithDuration:.3 animations:^{
            circleView.layer.opacity = opacity;
            circleView.transform = tr;
        }];
    }
    else{
        circleView.layer.opacity = opacity;
        circleView.transform = tr;
    }
}

- (void)setIsOtherMonth:(BOOL)isOtherMonth
{
    self->_isOtherMonth = isOtherMonth;
    [self setSelected:isSelected animated:NO];
}

- (void)reloadData
{
//    dotView.hidden = ![self.calendarManager.dataCache haveEvent:self.date];
    BOOL selected = [self isSameDate:[self.calendarManager currentDateSelected]];
    [self setSelected:selected animated:NO];
}

- (BOOL)isToday
{
    if(cacheIsToday == 0){
        return NO;
    }
    else if(cacheIsToday == 1){
        return YES;
    }
    else{
        if([self isSameDate:[NSDate date]]){
            cacheIsToday = 1;
            return YES;
        }
        else{
            cacheIsToday = 0;
            return NO;
        }
    }
}

- (BOOL)isSameDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:@"dd-MM-yyyy"]; //20-08-2015
    }
    
    if(!cacheCurrentDateText){
        cacheCurrentDateText = [dateFormatter stringFromDate:self.date];
    }
    
    //공휴일 계산 위함
    static NSDateFormatter *dateFormatter1;
    if(!dateFormatter1){
        dateFormatter1 = [NSDateFormatter new];
        dateFormatter1.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter1 setDateFormat:@"MM-dd"];
    }
    
    //개인 스케쥴 위함
    static NSDateFormatter *dateFormatter2;
    if(!dateFormatter2){
        dateFormatter2 = [NSDateFormatter new];
        dateFormatter2.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter2 setDateFormat:@"yyyy-MM-dd"];
    }
    
    //데이터 포맷 변환
    NSString *dateText2 = [dateFormatter stringFromDate:date];
    NSString *holiday = [dateFormatter1 stringFromDate:self.date];
    NSString *personalDay = [dateFormatter stringFromDate:self.date];
 
    
    //select all from DB - 주기적으로 정보를 바꿔줘야 새 정보를 가져올 수 있음
    [[DBInterface sharedDB] openDB];
//            [[DBInterface sharedDB] deleteRecord:@""];
    cumulative_titles = [[DBInterface sharedDB] getTitleRowsFromTbleNamed];
    
    for(int i = 0 ; i< [cumulative_titles count]; i++)
    {
        total_date[i] = [cumulative_titles[i] objectForKey:@"date"];
        total_title[i] = [cumulative_titles[i] objectForKey:@"title"];
        total_doby[i] = [cumulative_titles[i] objectForKey:@"body"];
    }
    
    //개인스케쥴
    for(int i=0; i < [total_date count] ; i++)
    {
        if([personalDay isEqualToString:[total_date objectAtIndex:i]] )
        {
            NSLog(@"textlabel에 들어갑 : %@", [total_title objectAtIndex:i]);
            textLabel2.text = [total_title objectAtIndex:i];
            return YES;
        }
    }
    //공휴일
    for(int i=0; i < [holidayArray count] ; i++)
    {
        if([holiday isEqualToString:[holidayArray objectAtIndex:i]] )
        {
            textLabel2.text = [holidayArrayName objectAtIndex:i];
            return YES;
        }
    }
    //클릭할때
    if ([cacheCurrentDateText isEqualToString:dateText2]) return YES;

    return NO;
}

- (NSInteger)monthIndexForDate:(NSDate *)date
{
    NSCalendar *calendar = self.calendarManager.calendarAppearance.calendar;
    NSDateComponents *comps = [calendar components:NSCalendarUnitMonth fromDate:date];
    return comps.month;
}

- (void)reloadAppearance
{
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = self.calendarManager.calendarAppearance.dayTextFont;
    backgroundView.backgroundColor = self.calendarManager.calendarAppearance.dayBackgroundColor;
    backgroundView.layer.borderWidth = self.calendarManager.calendarAppearance.dayBorderWidth;
    backgroundView.layer.borderColor = self.calendarManager.calendarAppearance.dayBorderColor.CGColor;
    
    [self configureConstraintsForSubviews];
    [self setSelected:isSelected animated:NO];
}

@end
