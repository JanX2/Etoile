#!/bin/bash

# This script must be sourced into build.sh

. $SCRIPT_DIR/mail.config

USERNAME_OPT=
PASSWORD_OPT=

if [ -n "$MAIL_SMTP_USERNAME" ]; then 
	USERNAME_OPT="-xu $MAIL_SMTP_USERNAME"
	PASSWORD_OPT="-xp $MAIL_SMTP_PASSWORD"
fi

#echo $USERNAME_OPT $PASSWORD_OPT

sendemail -f $MAIL_FROM -t $MAIL_TO -s $MAIL_SMTP_SERVER $USERNAME_OPT $PASSWORD_OPT $MAIL_OPTIONS -u "$MAIL_SUBJECT" -a $MAIL_ATTACHMENTS -m "$MAIL_BODY"
STATUS=$?

if [ $STATUS -ne 0 ]; then
	echo
	echo " === WARNING: Failed to send mail, something is wrong in the mail configuration or at the SMTP server level... === "
	echo
	echo "Mail Variables"
	echo
	echo "MAIL_FROM = $MAIL_FROM"
	echo "MAIL_TO = $MAIL_TO"
	echo "MAIL_SMTP_SERVER = $MAIL_SMTP_SERVER"
	echo "MAIL_SMTP_USERNAME = $MAIL_SMTP_USERNAME"
	echo "MAIL_ATTACHMENTS = $MAIL_ATTACHMENTS"
	echo "MAIL_BODY = $MAIL_BODY"
	echo
fi

