//
//  RangePickerViewController.m
//  FSCalendar
//
//  Created by dingwenchao on 5/8/16.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

#import "RangePickerViewController.h"
#import "FSCalendar.h"
#import "RangePickerCell.h"
#import "FSCalendarExtensions.h"
#import "DIYCalendarCell.h"

@interface RangePickerViewController () <FSCalendarDataSource,FSCalendarDelegate,FSCalendarDelegateAppearance>

@property (weak, nonatomic) FSCalendar *calendar;

@property (weak, nonatomic) UILabel *eventLabel;
@property (strong, nonatomic) NSCalendar *gregorian;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

// The start date of the range
@property (strong, nonatomic) NSDate *startDate;
// The end date of the range
@property (strong, nonatomic) NSDate *endDate;

- (void)configureCell:(__kindof FSCalendarCell *)cell forDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)position;

@end

@implementation RangePickerViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"FSCalendar";
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
    
    FSCalendar *calendar = [[FSCalendar alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame), view.frame.size.width, view.frame.size.height - CGRectGetMaxY(self.navigationController.navigationBar.frame))];
    calendar.dataSource = self;
    calendar.delegate = self;
    calendar.pagingEnabled = NO;
    calendar.allowsMultipleSelection = YES;
    calendar.rowHeight = 50;
    calendar.placeholderType = FSCalendarPlaceholderTypeNone;
    [view addSubview:calendar];
    self.calendar = calendar;
    
    calendar.appearance.titleDefaultColor = [UIColor blackColor];
    calendar.appearance.headerTitleColor = [UIColor blackColor];
    calendar.appearance.titleFont = [UIFont systemFontOfSize:16];
    calendar.weekdayHeight = 0;
    
    calendar.swipeToChooseGesture.enabled = YES;
    
    //calendar.today = nil; // Hide the today circle
    [calendar registerClass:[DIYCalendarCell class] forCellReuseIdentifier:@"cell"];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gregorian = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    // Uncomment this to perform an 'initial-week-scope'
    // self.calendar.scope = FSCalendarScopeWeek;
    
    // For UITest
    self.calendar.accessibilityIdentifier = @"calendar";
}

- (void)dealloc
{
    NSLog(@"%s",__FUNCTION__);
}

#pragma mark - FSCalendarDataSource

- (NSDate *)minimumDateForCalendar:(FSCalendar *)calendar
{
    return [self.dateFormatter dateFromString:@"2016-07-08"];
}

- (NSDate *)maximumDateForCalendar:(FSCalendar *)calendar
{
    return [self.gregorian dateByAddingUnit:NSCalendarUnitMonth value:10 toDate:[NSDate date] options:0];
}

- (FSCalendarCell *)calendar:(FSCalendar *)calendar cellForDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
{
    RangePickerCell *cell = [calendar dequeueReusableCellWithIdentifier:@"cell" forDate:date atMonthPosition:monthPosition];
    return cell;
}

- (void)calendar:(FSCalendar *)calendar willDisplayCell:(FSCalendarCell *)cell forDate:(NSDate *)date atMonthPosition: (FSCalendarMonthPosition)monthPosition
{
    [self configureCell:cell forDate:date atMonthPosition:monthPosition];
}

#pragma mark - FSCalendarDelegate

- (BOOL)calendar:(FSCalendar *)calendar shouldSelectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
{
    return monthPosition == FSCalendarMonthPositionCurrent;
}

- (BOOL)calendar:(FSCalendar *)calendar shouldDeselectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
{
    return NO;
}

- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
{
    
    if (calendar.swipeToChooseGesture.state == UIGestureRecognizerStateChanged) {
        // If the selection is caused by swipe gestures
        if (!self.startDate) {
            self.startDate = date;
        } else {
            if (self.endDate) {
                [calendar deselectDate:self.endDate];
            }
            self.endDate = date;
        }
    } else {
        if (self.endDate) {
            [calendar deselectDate:self.startDate];
            [calendar deselectDate:self.endDate];
            self.startDate = date;
            self.endDate = nil;
        } else if (!self.startDate) {
            self.startDate = date;
        } else {
            self.endDate = date;
        }
        
    }
    
    [self configureVisibleCells];
}

- (void)calendar:(FSCalendar *)calendar didDeselectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
{
    NSLog(@"did deselect date %@",[self.dateFormatter stringFromDate:date]);
    [self configureVisibleCells];
}

- (NSArray<UIColor *> *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance eventDefaultColorsForDate:(NSDate *)date
{
    if ([self.gregorian isDateInToday:date]) {
        return @[[UIColor orangeColor]];
    }
    return @[appearance.eventDefaultColor];
}

#pragma mark - Private methods

- (void)configureVisibleCells
{
    [self.calendar.visibleCells enumerateObjectsUsingBlock:^(__kindof FSCalendarCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDate *date = [self.calendar dateForCell:obj];
        FSCalendarMonthPosition position = [self.calendar monthPositionForCell:obj];
        [self configureCell:obj forDate:date atMonthPosition:position];
    }];
}

- (void)configureCell:(__kindof FSCalendarCell *)cell forDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)position
{
    DIYCalendarCell *rangeCell = cell;
    if (position != FSCalendarMonthPositionCurrent) {
        rangeCell.selectionLayer.hidden = YES;
        return;
    }
    BOOL isMiddle = NO;
    if (self.startDate && self.endDate) {
        // The date is in the middle of the range
        isMiddle = [date compare:self.startDate] != [date compare:self.endDate];
    }
    else {
        rangeCell.selectionType = SelectionTypeNone;
    }
    BOOL isStartDate = NO;
    BOOL isEndDate = NO;
    isStartDate |= self.startDate && [self.gregorian isDate:date inSameDayAsDate:self.startDate];
    isEndDate |= self.endDate && [self.gregorian isDate:date inSameDayAsDate:self.endDate];
    if (isStartDate) {
        rangeCell.subtitle = @"start";
        rangeCell.selectionType = self.endDate ? SelectionTypeLeftBorder : SelectionTypeSingle;
    }
    else if(isEndDate) {
        rangeCell.subtitle = @"end";
        rangeCell.selectionType = self.startDate ? SelectionTypeRightBorder : SelectionTypeSingle;
    }
    else if(isMiddle) {
        rangeCell.selectionType = SelectionTypeMiddle;
    }
    else {
        rangeCell.selectionType = SelectionTypeNone;
    }
}

@end
