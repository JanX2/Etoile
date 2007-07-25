//
//  Constants.h
//  Vienna
//
//  Created by Steve on Sat Jan 24 2004.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

extern NSString *MA_Notify_GotAuthenticationForFolder;
extern NSString *MA_Notify_CancelAuthenticationForFolder;
extern NSString *MA_Notify_WillDeleteFolder;
extern NSString *MA_Notify_FoldersUpdated;
extern NSString *MA_Notify_RefreshStatus;
extern NSString *MA_Notify_Refreshing_Progress;
extern NSString *MA_Notify_FolderSelectionChange;
extern NSString *MA_Notify_CheckFrequencyChange;
extern NSString *MA_Notify_PreferenceChange;
extern NSString *MA_Notify_EditFolder;
extern NSString *MA_Notify_FolderNameChanged;
extern NSString *MA_Notify_StatusBarChanged;

extern NSString *MA_DefaultStyleName;
extern NSString *MA_DefaultUserAgentString;

extern NSString *MAPref_ArticleListFont;
extern NSString *MAPref_AutoSortFoldersTree;
extern NSString *MAPref_CheckForUpdatedArticles;
extern NSString *MAPref_ShowUnreadArticlesInBold;
extern NSString *MAPref_FolderFont;
extern NSString *MAPref_CachedFolderID;
extern NSString *MAPref_DefaultDatabase;
extern NSString *MAPref_DownloadsFolder;
extern NSString *MAPref_SortColumn;
extern NSString *MAPref_CheckFrequency;
extern NSString *MAPref_ArticleListColumns;
extern NSString *MAPref_CheckForNewArticlesOnStartup;
extern NSString *MAPref_FolderImagesFolder;
extern NSString *MAPref_RefreshThreads;
extern NSString *MAPref_ActiveStyleName;
extern NSString *MAPref_StylesFolder;
extern NSString *MAPref_FolderStates;
extern NSString *MAPref_BacktrackQueueSize;
extern NSString *MAPref_MarkReadInterval;
extern NSString *MAPref_SelectionChangeInterval;
extern NSString *MAPref_OpenLinksInBackground;
extern NSString *MAPref_MinimumFontSize;
extern NSString *MAPref_UseMinimumFontSize;
extern NSString *MAPref_AutoExpireDuration;
extern NSString *MAPref_DownloadsList;
extern NSString *MAPref_ShowFolderImages;
extern NSString *MAPref_UseJavaScript;
extern NSString *MAPref_CachedArticleGUID;
extern NSString *MAPref_ArticleSortDescriptors;
extern NSString *MAPref_FilterMode;
extern NSString *MAPref_LastRefreshDate;
extern NSString *MAPref_Layout;
extern NSString *MAPref_Profile_Path;
extern NSString *MAPref_EmptyTrashNotification;
extern NSString *MAPref_ShowStatusBar;

extern const int   MA_Default_BackTrackQueueSize;
extern const int   MA_Default_RefreshThreads;
extern const float MA_Default_Read_Interval;
extern const float MA_Default_Selection_Change_Interval;
extern const int   MA_Default_MinimumFontSize;
extern const int   MA_Default_AutoExpireDuration;

extern NSString *MA_PBoardType_RSSItem;
extern NSString *MA_PBoardType_FolderList;
extern NSString *MA_PBoardType_RSSSource;
extern NSString *MA_PBoardType_url;
extern NSString *MA_PBoardType_urln;

// Filtering options
#define MA_Filter_All					0
#define MA_Filter_Unread				1
#define MA_Filter_LastRefresh			2
#define MA_Filter_Today					3
#define MA_Filter_Flagged				4

// Search options
#define MA_Search_All				888
#define MA_Search_Selected_Folder	889

// Refresh folder options
#define MA_Refresh_RedrawList			0
#define MA_Refresh_ReapplyFilter		1
#define MA_Refresh_ReloadFromDatabase	2
#define MA_Refresh_SortAndRedraw		3

// View animation tags
#define MA_ViewTag_Statusbar			2

// Layout styles
#define MA_Layout_Report				1
#define MA_Layout_Condensed				2
#define MA_Layout_Unified				3

// Folders tree sort method
#define MA_FolderSort_Manual			0
#define MA_FolderSort_ByName			1

// Empty trash option on quitting
#define MA_EmptyTrash_None				0
#define MA_EmptyTrash_WithoutWarning	1
#define MA_EmptyTrash_WithWarning		2

