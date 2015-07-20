//
//  DBInterface.m
//  example7
//
//  Created by smart on 15. 5. 20..
//  Copyright (c) 2015년 smartmobile leehyo. All rights reserved.
//

#import "DBInterface.h"
#import <sqlite3.h>

@implementation DBInterface

//싱글톤 객체를 반환
//static DBInterface *dbinit;
+(id)sharedDB
{
    //멀티스레드로 초기화를 수행한다. 메모리를 더욱 효율적으로 관리할 수 있다.
    // 1
    static DBInterface *_sharedInstance = nil;
    
    // 2
    static dispatch_once_t oncePredicate;
    
    // 3
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DBInterface alloc] init];
    });
    return _sharedInstance;
}

//데이터베이스 파일 전체 경로를 반환한다.
-(NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    return [documentsDir stringByAppendingPathComponent:@"memo.db"];
    
}

//데이터베이스를 생성하여 연다.
-(void)openDB
{
    if(sqlite3_open([[self filePath]UTF8String],&db) != SQLITE_OK)
    {
        sqlite3_close(db);
        NSAssert(0, @"Database failed to open.");
    }
}

-(void) createTableNamed:(NSString *) tableName withField1:(NSString *) field1 withField2:(NSString *) field2
{
    char *err;

    //, id integer primary key autoincrement, position integer
    NSString *sql = [NSString stringWithFormat:@"create table if not exists memo (title TEXT, body TEXT, date TEXT primary key unique);"];
    
    if(sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK)
    {
        sqlite3_close(db);
        NSAssert(0,@"Table failed to create..");
    }
}

//레코드를 삽입한다.
-(void)insertRecord:(NSString *)tableName title:(NSString *)title body:(NSString *)body date:(NSString *)date
{
    NSLog(@"insertRecord in ! title is %@ , body is %@", title, body);
    NSString *sql1 = [NSString stringWithFormat:@"insert or replace into '%@' ('title','body', 'date') values ('%@', '%@',  '%@')", tableName,title, body, date];
    
   NSString *sql2 = [NSString stringWithFormat:@"update memo set position = id where title='%@'", title];
    
    char *err;
    
    if(sqlite3_exec(db, [sql1 UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"Error inserting table.");
    }
    
    if(sqlite3_exec(db, [sql2 UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"Error inserting table.");
    }
    
}

//레코드를 업데이트한다.
-(void)updateRecord:(NSString *)tableName title:(NSString *)title body:(NSString *)body original_title:(NSString *)original_title
{
    NSLog(@"updateRecord in ! title is %@ , body is %@", title, body);
    NSString *sql = [NSString stringWithFormat:@"update memo set title='%@',body='%@' where title='%@' ", title, body,original_title];
//    NSLog(@"sql is %@", sql);
    char *err;
    if(sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"Error updating table.");
    }
}

//레코드를 삭제한다.
-(void)deleteRecord: (NSString*)keyword
{
    NSLog(@"1. delete function in title is %@", keyword);
    NSString *sql;
    if([keyword  isEqual: @""])
    {
        sql = [NSString stringWithFormat:@"delete from memo"];
    }
    else
    {
        sql = [NSString stringWithFormat:@"delete from memo where title= '%@' ", keyword];
        NSLog(@"sql is %@", sql);
    }
    
    
    char *err;
    if(sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"Error deleting record.");
    }
}

//테이블 이름으로 레코드를 가져온다.
-(NSMutableArray*) getTitleRowsFromTbleNamed
{
    //리턴할 title 값들의 배열
    NSMutableArray* memos;
    memos = [[NSMutableArray alloc]initWithCapacity:0];
    
    //열을 가져온다.
    NSString *qsql = [NSString stringWithFormat:@"select * from memo order by position desc"];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(db, [qsql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        //prepared 문을 실행하기 위해서 sqlite3_step() 함수를 사용한다.
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            char *field1 = (char *) sqlite3_column_text(statement, 0);
            NSString *get_title = [[NSString alloc] initWithUTF8String:field1];
            
            char *field2 = (char *) sqlite3_column_text(statement, 1);
            NSString *get_body = [[NSString alloc] initWithUTF8String:field2];
            
            char *field3 = (char *) sqlite3_column_text(statement, 2);
            NSString *get_date = [[NSString alloc] initWithUTF8String:field3];
            
            char *field4 = (char *) sqlite3_column_text(statement, 3);
            NSString *get_id = [[NSString alloc] initWithUTF8String:field4];
           
            char *field5 = (char *) sqlite3_column_text(statement, 4);
            NSString *get_index = [[NSString alloc] initWithUTF8String:field5];
            
            NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
            [mDict setObject:get_title forKey:@"title"];
            [mDict setObject:get_body forKey:@"body"];
            [mDict setObject:get_date forKey:@"date"];
            [mDict setObject:get_id forKey:@"id"];
            [mDict setObject:get_index forKey:@"position"];
            
            [memos addObject:mDict]; //배열에 차례로 값을 추가한다.
        }
        //메모리에 쌓인 쿼리문을 삭제한다.
        sqlite3_finalize(statement);
    }
    sqlite3_close(db);
    return memos;
}


//제목을 받아 자세한 레코드를 가져온다.
-(NSMutableArray*) getDetailedMemoFromKeyword:(NSString*)keyword
{
    //리턴할 title 값들의 배열
    NSMutableArray* memos;
    memos = [[NSMutableArray alloc]initWithCapacity:0];
    
    //열을 가져온다.
    NSString *qsql = [NSString stringWithFormat:@"select * from memo where id = %@", keyword];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(db, [qsql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        //prepared 문을 실행하기 위해서 sqlite3_step() 함수를 사용한다.
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            char *field1 = (char *) sqlite3_column_text(statement, 0);
            NSString *get_title = [[NSString alloc] initWithUTF8String:field1];
            
            char *field2 = (char *) sqlite3_column_text(statement, 1);
            NSString *get_body = [[NSString alloc] initWithUTF8String:field2];
            
            char *field3 = (char *) sqlite3_column_text(statement, 2);
            NSString *get_date = [[NSString alloc] initWithUTF8String:field3];
            
            [memos addObject:get_title];
            [memos addObject:get_body];
            [memos addObject:get_date];
        }
        //메모리에 쌓인 쿼리문을 삭제한다.
        sqlite3_finalize(statement);
    }
    sqlite3_close(db);
    return memos;
}
@end
