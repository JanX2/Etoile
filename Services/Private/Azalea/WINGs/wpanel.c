

#include "WINGsP.h"

#include <X11/keysym.h>



static void
alertPanelOnClick(WMWidget *self, void *clientData)
{
    WMAlertPanel *panel = clientData;

    WMBreakModalLoop(WMWidgetScreen(self));
    if (self == panel->defBtn) {
        panel->result = WAPRDefault;
    } else if (self == panel->othBtn) {
        panel->result = WAPROther;
    } else if (self == panel->altBtn) {
        panel->result = WAPRAlternate;
    }
}


static void
handleKeyPress(XEvent *event, void *clientData)
{
    WMAlertPanel *panel = (WMAlertPanel*)clientData;
    KeySym ksym;

    XLookupString(&event->xkey, NULL, 0, &ksym, NULL);

    if (ksym == XK_Return && panel->defBtn) {
        WMPerformButtonClick(panel->defBtn);
    } else if (ksym == XK_Escape) {
        if (panel->altBtn || panel->othBtn) {
            WMPerformButtonClick(panel->othBtn ? panel->othBtn : panel->altBtn);
        } else {
            panel->result = WAPRDefault;
            WMBreakModalLoop(WMWidgetScreen(panel->win));
        }
    }
}


int
WMRunAlertPanel(WMScreen *scrPtr, WMWindow *owner,
                char *title, char *msg, char *defaultButton,
                char *alternateButton, char *otherButton)
{
    WMAlertPanel *panel;
    int tmp;

    panel = WMCreateAlertPanel(scrPtr, owner, title, msg, defaultButton,
                               alternateButton, otherButton);

    {
        int px, py;
        WMView *view = WMWidgetView(panel->win);

        if (owner) {
            WMView *oview = WMWidgetView(owner);
            WMPoint pt = WMGetViewScreenPosition(oview);

            px = (W_VIEW_WIDTH(oview)-W_VIEW_WIDTH(view))/2;
            py = (W_VIEW_HEIGHT(oview)-W_VIEW_HEIGHT(view))/2;

            px += pt.x;
            py += pt.y;
        } else {
            px = (W_VIEW_WIDTH(scrPtr->rootView)-W_VIEW_WIDTH(view))/2;
            py = (W_VIEW_HEIGHT(scrPtr->rootView)-W_VIEW_HEIGHT(view))/2;
        }
        WMSetWindowInitialPosition(panel->win, px, py);
    }

    WMMapWidget(panel->win);

    WMRunModalLoop(scrPtr, W_VIEW(panel->win));

    tmp = panel->result;

    WMDestroyAlertPanel(panel);

    return tmp;
}


void
WMDestroyAlertPanel(WMAlertPanel *panel)
{
    WMUnmapWidget(panel->win);
    WMDestroyWidget(panel->win);
    wfree(panel);
}


WMAlertPanel*
WMCreateAlertPanel(WMScreen *scrPtr, WMWindow *owner,
                   char *title, char *msg, char *defaultButton,
                   char *alternateButton, char *otherButton)
{
    WMAlertPanel *panel;
    int dw=0, aw=0, ow=0, w;
    WMBox *hbox;
    WMPixmap *icon;


    panel = wmalloc(sizeof(WMAlertPanel));
    memset(panel, 0, sizeof(WMAlertPanel));

    if (owner) {
        panel->win = WMCreatePanelWithStyleForWindow(owner, "alertPanel",
                                                     WMTitledWindowMask);
    } else {
        panel->win = WMCreateWindowWithStyle(scrPtr, "alertPanel",
                                             WMTitledWindowMask);
    }

    WMSetWindowInitialPosition(panel->win,
                               (scrPtr->rootView->size.width - WMWidgetWidth(panel->win))/2,
                               (scrPtr->rootView->size.height - WMWidgetHeight(panel->win))/2);

    WMSetWindowTitle(panel->win, "");

    panel->vbox = WMCreateBox(panel->win);
    WMSetViewExpandsToParent(WMWidgetView(panel->vbox), 0, 0, 0, 0);
    WMSetBoxHorizontal(panel->vbox, False);
    WMMapWidget(panel->vbox);

    hbox = WMCreateBox(panel->vbox);
    WMSetBoxBorderWidth(hbox, 5);
    WMSetBoxHorizontal(hbox, True);
    WMMapWidget(hbox);
    WMAddBoxSubview(panel->vbox, WMWidgetView(hbox), False, True, 74, 0, 5);

    panel->iLbl = WMCreateLabel(hbox);
    WMSetLabelImagePosition(panel->iLbl, WIPImageOnly);
    WMMapWidget(panel->iLbl);
    WMAddBoxSubview(hbox, WMWidgetView(panel->iLbl), False, True, 64, 0, 10);
    icon = WMCreateApplicationIconBlendedPixmap(scrPtr, (RColor*)NULL);
    if (icon) {
        WMSetLabelImage(panel->iLbl, icon);
        WMReleasePixmap(icon);
    } else {
        WMSetLabelImage(panel->iLbl, scrPtr->applicationIconPixmap);
    }

    if (title) {
        WMFont *largeFont;

        largeFont = WMBoldSystemFontOfSize(scrPtr, 24);

        panel->tLbl = WMCreateLabel(hbox);
        WMMapWidget(panel->tLbl);
        WMAddBoxSubview(hbox, WMWidgetView(panel->tLbl), True, True,
                        64, 0, 0);
        WMSetLabelText(panel->tLbl, title);
        WMSetLabelTextAlignment(panel->tLbl, WALeft);
        WMSetLabelFont(panel->tLbl, largeFont);

        WMReleaseFont(largeFont);
    }

    /* create divider line */

    panel->line = WMCreateFrame(panel->win);
    WMMapWidget(panel->line);
    WMAddBoxSubview(panel->vbox, WMWidgetView(panel->line), False, True,
                    2, 2, 5);
    WMSetFrameRelief(panel->line, WRGroove);


    if (msg) {
        panel->mLbl = WMCreateLabel(panel->vbox);
        WMSetLabelWraps(panel->mLbl, True);
        WMMapWidget(panel->mLbl);
        WMAddBoxSubview(panel->vbox, WMWidgetView(panel->mLbl), True, True,
                        WMFontHeight(scrPtr->normalFont)*4, 0, 5);
        WMSetLabelText(panel->mLbl, msg);
        WMSetLabelTextAlignment(panel->mLbl, WACenter);
    }

    panel->hbox = WMCreateBox(panel->vbox);
    WMSetBoxBorderWidth(panel->hbox, 10);
    WMSetBoxHorizontal(panel->hbox, True);
    WMMapWidget(panel->hbox);
    WMAddBoxSubview(panel->vbox, WMWidgetView(panel->hbox), False, True, 44, 0, 0);

    /* create buttons */
    if (otherButton)
        ow = WMWidthOfString(scrPtr->normalFont, otherButton,
                             strlen(otherButton));

    if (alternateButton)
        aw = WMWidthOfString(scrPtr->normalFont, alternateButton,
                             strlen(alternateButton));

    if (defaultButton)
        dw = WMWidthOfString(scrPtr->normalFont, defaultButton,
                             strlen(defaultButton));

    dw = dw + (scrPtr->buttonArrow ? scrPtr->buttonArrow->width : 0);

    aw += 30;
    ow += 30;
    dw += 30;

    w = WMAX(dw, WMAX(aw, ow));
    if ((w+10)*3 < 400) {
        aw = w;
        ow = w;
        dw = w;
    } else {
        int t;

        t = 400 - 40 - aw - ow - dw;
        aw += t/3;
        ow += t/3;
        dw += t/3;
    }

    if (defaultButton) {
        panel->defBtn = WMCreateCommandButton(panel->hbox);
        WMSetButtonAction(panel->defBtn, alertPanelOnClick, panel);
        WMAddBoxSubviewAtEnd(panel->hbox, WMWidgetView(panel->defBtn),
                             False, True, dw, 0, 0);
        WMSetButtonText(panel->defBtn, defaultButton);
        WMSetButtonImage(panel->defBtn, scrPtr->buttonArrow);
        WMSetButtonAltImage(panel->defBtn, scrPtr->pushedButtonArrow);
        WMSetButtonImagePosition(panel->defBtn, WIPRight);
    }
    if (alternateButton) {
        panel->altBtn = WMCreateCommandButton(panel->hbox);
        WMAddBoxSubviewAtEnd(panel->hbox, WMWidgetView(panel->altBtn),
                             False, True, aw, 0, 5);
        WMSetButtonAction(panel->altBtn, alertPanelOnClick, panel);
        WMSetButtonText(panel->altBtn, alternateButton);
    }
    if (otherButton) {
        panel->othBtn = WMCreateCommandButton(panel->hbox);
        WMSetButtonAction(panel->othBtn, alertPanelOnClick, panel);
        WMAddBoxSubviewAtEnd(panel->hbox, WMWidgetView(panel->othBtn),
                             False, True, ow, 0, 5);
        WMSetButtonText(panel->othBtn, otherButton);
    }

    WMMapSubwidgets(panel->hbox);

    WMCreateEventHandler(W_VIEW(panel->win), KeyPressMask,
                         handleKeyPress, panel);

    WMRealizeWidget(panel->win);
    WMMapSubwidgets(panel->win);

    return panel;
}

