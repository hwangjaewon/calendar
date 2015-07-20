//
//  DBInterface.h
//  example7
//
//  Created by smart on 15. 5. 20..
//  Copyright (c) 2015년 smartmobile leehyo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "DBInterface.h"
@class DBInterface;

@interface DBInterface : NSObject
{
    sqlite3 *db;
}

+ (id)sharedDB;
-(NSString *) filePath; // Sqlite 데이터베이스의 전체 경로를 반환한다.
-(void)openDB; //데이터베이스를 생성하여 연다.
-(void)insertRecord:(NSString *)tableName title:(NSString *)title body:(NSString *)body date:(NSString *)date;
-(void)updateRecord:(NSString *)tableName title:(NSString *)title body:(NSString *)body original_title:(NSString *)original_title;
-(NSMutableArray*) getTitleRowsFromTbleNamed;//타이틀 레코드를 가져온다.
-(void) createTableNamed:(NSString *) tableName withField1:(NSString *) field1 withField2:(NSString *) field2; //테이블을 생성한다.
-(void)deleteRecord: (NSString*)keyword;
-(NSMutableArray*) getDetailedMemoFromKeyword:(NSString*)keyword;
-(void)updateChangePositionRecord:(NSString *)id1 : (NSString *)id2; //position순서를 바꿔주어 레코드 순서를 바꾼다.
@end
