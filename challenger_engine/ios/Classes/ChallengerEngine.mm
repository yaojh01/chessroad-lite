//
//  ChallengerEngine.mm
//  Runner
//
//  Created by 贺照云 on 2022/9/1.
//  Copyright © 2022 The Chromium Authors. All rights reserved.
//

#import "ChallengerEngine.h"
#import "challenger.h"
#import "challenger-channel.h"

@implementation ChallengerEngine

@synthesize state;

- (id)init {
    
    self = [super init];
    
    if (self) {
        state = Ready;
    }
    
    return self;
}

- (void)engineThread:(id)data {
    
    NSLog(@"Engine Think Thread enter.\n");
    
    challengerMain();
    
    NSLog(@"Engine Think Thread exit.\n");
}

-(int) startup {
    
    if (operationQueue != nil) {
        [operationQueue cancelAllOperations];
        operationQueue = nil;
    }
    
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:1];
    
    // getInstance() 有并发问题，这里首先主动建立实例，避免后续创建重复
    CommandChannel::getInstance();
    usleep(10);
    
    [operationQueue addOperation:[[NSInvocationOperation alloc]
                                  initWithTarget:self
                                  selector:@selector(engineThread:)
                                  object:nil]];
    
    [self send:@"ucci"];
    
    return 0;
}

-(int) changeSearchDepth: (int) depth {
    
    if (depth > 0 && depth <= 64) {
        SearchDepth = depth;
        PrintLn("SearchDepth: %d", depth);
        return 0;
    }
    
    return -1;
}

-(int) send: (NSString *) command {
    
    if ([command hasPrefix:@"go"]) {
        // state = Thinking;
    }
    
    CommandChannel *channel = CommandChannel::getInstance();
    
    if (channel->pushCommand([command UTF8String])) {
        NSLog(@"===>>> %@\n", command);
        return 0;
    }
    
    return -1;
}

-(NSString *) read {
    
    CommandChannel *channel = CommandChannel::getInstance();
    char buffer[4096] = {0};
    
    bool got_response = channel->popupResponse(buffer);
    if (!got_response) return nil;
    
    NSString *line = [NSString stringWithFormat:@"%s", buffer];
    NSLog(@"<<<=== %@\n", line);
    
    if ([line isEqualToString:@"readyok"] ||
        [line isEqualToString:@"ucciok"] ||
        [line hasPrefix:@"bestmove"] ||
        [line hasPrefix:@"nobestmove"]) {
        
        state = Ready;
    }
    
    return line;
}

-(int) shutdown {
    
    [self send:@"quit"];
    
    [operationQueue cancelAllOperations];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    operationQueue = nil;
    
    return 0;
}

-(BOOL) isReady {
    return state == Ready;
}

-(BOOL) isThinking {
    return state == Thinking;
}

@end
