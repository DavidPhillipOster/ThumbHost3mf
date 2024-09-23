//
//  ImageView.m
//  ThumbHost3mf
//
//  Created by david on 9/19/24.
//

#import "ImageView.h"

@interface ImageView ()
@property(nonatomic) BOOL isInDrop;
@property(nonatomic) NSURL *destinationDir;
@property(nonatomic) NSOperationQueue *workQueue;
@end

@implementation ImageView

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
  if (self.isInDrop) {
    CGRect bounds = CGRectInset(self.bounds, 5, 5);
    [NSColor.blueColor set];
    NSFrameRect(bounds);
    bounds = CGRectInset(bounds, 1, 1);
    NSFrameRect(bounds);
  }
}

- (NSOperationQueue *)workQueue {
  if (nil == _workQueue) {
    _workQueue = [[NSOperationQueue alloc] init];
    _workQueue.qualityOfService = NSQualityOfServiceUserInitiated;
  }
  return _workQueue;
}


- (void)setIsInDrop:(BOOL)isInDrop {
  if (_isInDrop != isInDrop) {
    _isInDrop = isInDrop;
    [self setNeedsDisplay:YES];
  }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
  self.isInDrop = YES;
  return NSDragOperationGeneric;
}

- (void)draggingExited:(nullable id <NSDraggingInfo>)sender {
  self.isInDrop = NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
  return YES;
}

- (void)concludeDragOperation:(nullable id <NSDraggingInfo>)sender {
  self.isInDrop = NO;
}

- (void)handleFileURL:(NSURL *)url {
  [NSApp.delegate application:NSApp openFile:[url path]];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
  self.isInDrop = NO;
  NSArray<NSDictionary *> *documentTypes = [NSBundle.mainBundle objectForInfoDictionaryKey:@"UTImportedTypeDeclarations"];
  NSArray<NSString *> *typeUTIs = [documentTypes valueForKey:@"UTTypeIdentifier"];
//  NSLog(@"%@", typeUTIs);
  [sender enumerateDraggingItemsWithOptions:0
          forView:self
          classes:@[ [NSFilePromiseReceiver class], [NSURL class] ]
          searchOptions:@{NSPasteboardURLReadingFileURLsOnlyKey : @YES,
                          NSPasteboardURLReadingContentsConformToTypesKey : typeUTIs}
          usingBlock:^(NSDraggingItem *dragging, NSInteger idx, BOOL *stop){
            if ([dragging.item isKindOfClass:[NSFilePromiseReceiver class]]) {
              NSFilePromiseReceiver *receiver = (NSFilePromiseReceiver *)dragging.item;
              [receiver receivePromisedFilesAtDestination:self.destinationDir
              options:@{}
              operationQueue:self.workQueue
              reader:^(NSURL *fileURL, NSError *errorOrNil) {
                [self handleFileURL:fileURL];
              }];
            } else if ([dragging.item isKindOfClass:[NSURL class]]) {
              [self handleFileURL:(NSURL *)dragging.item];
            }
          }];
  return YES;
}

@end
