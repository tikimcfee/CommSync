//
//   Copyright 2014 Slack Technologies, Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <UIKit/UIKit.h>

/** @name UIScrollView additional features used for SlackTextViewController. */
@interface UIScrollView (SLKAdditions)

/** The accurate CGPoint offset to reach the top of the scrollView. */
@property (nonatomic, readonly) CGPoint slk_topOffset;
/** The accurate CGPoint offset to reach the bottom of the scrollView. */
@property (nonatomic, readonly) CGPoint slk_bottomOffset;

/** YES if the scrollView's offset is at the very top. */
@property (nonatomic, readonly) BOOL slk_isAtTop;
/** YES if the scrollView's offset is at the very bottom. */
@property (nonatomic, readonly) BOOL slk_isAtBottom;
/** YES if the scrollView can scroll from it's current offset position to the bottom. */
@property (nonatomic, readonly) BOOL slk_canScrollToBottom;

/** The vertical scroll indicator view. */
@property (nonatomic, readonly) UIView *slk_verticalScroller;
/** The horizontal scroll indicator view. */
@property (nonatomic, readonly) UIView *slk_horizontalScroller;

/**
 Sets the content offset to the top.
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)slk_scrollToTopAnimated:(BOOL)animated;

/**
 Sets the content offset to the bottom.
 @param animated YES to animate the transition at a constant velocity to the new offset, NO to make the transition immediate.
 */
- (void)slk_scrollToBottomAnimated:(BOOL)animated;

/**
 Stops scrolling, if it was scrolling.
 */
- (void)slk_stopScrolling;

@end
