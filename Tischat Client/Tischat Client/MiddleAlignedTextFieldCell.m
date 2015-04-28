//
//  MiddleAlignedTextFieldCell.m
//  Tischat Client
//
//  Created by Bryan McLemore on 2010-01-20
//  See http://stackoverflow.com/questions/2103125/vertically-aligning-text-in-nstableview-row#answer-2103161
//

#import "MiddleAlignedTextFieldCell.h"

@implementation MiddleAlignedTextFieldCell

- (NSRect)titleRectForBounds:(NSRect)theRect {
    NSRect titleFrame = [super titleRectForBounds:theRect];
    NSSize titleSize = [[self attributedStringValue] size];
    titleFrame.origin.y = theRect.origin.y - .5 + (theRect.size.height - titleSize.height) / 2.0;
    return titleFrame;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect titleRect = [self titleRectForBounds:cellFrame];
    [[self attributedStringValue] drawInRect:titleRect];
}

@end
