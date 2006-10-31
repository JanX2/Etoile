#import <Foundation/Foundation.h>

extern NSString *const kArticleHeadlineProperty;
extern NSString *const kArticleURLProperty;
extern NSString *const kArticleDescriptionProperty;
extern NSString *const kArticleDateProperty;
extern NSString *const kArticleReadProperty;

/* This property matches url of feed in feedStore */
extern NSString *const kArticleGroupURLProperty;

/* When feed list changed, mostly due to a fetch of rss.
 * Object is the changed feed. */
extern NSString *const RSSReaderFeedListChangedNotification;

/* Toolbar */
extern NSString *const RSSReaderToolbarIdentifier;
extern NSString *const RSSReaderSubscribeToolbarItemIdentifier;
extern NSString *const RSSReaderRefreshAllToolbarItemIdentifier;
extern NSString *const RSSReaderSearchToolbarItemIdentifier;

/* Frame name for saving */
extern NSString *const RSSReaderMainWindowFrameName;
