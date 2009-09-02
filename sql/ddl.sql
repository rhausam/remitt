# $Id$
#
# Authors:
# 	Jeff Buchbinder <jeff@freemedsoftware.org>
#
# REMITT Electronic Medical Information Translation and Transmission
# Copyright (C) 1999-2009 FreeMED Software Foundation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

DROP TABLE IF EXISTS `tUser`;
CREATE TABLE `tUser` (
	  id		SERIAL
	, username	VARCHAR(50) NOT NULL UNIQUE KEY
	, passhash	CHAR(16) NOT NULL
	, apiurl	VARCHAR(150) COMMENT 'For later use'
);

INSERT INTO `tUser` VALUES ( 1, 'Administrator', MD5('password'), NULL );

DROP TABLE IF EXISTS `tRole`;
CREATE TABLE `tRole` (
	  id		SERIAL
	, username	VARCHAR(50) NOT NULL
	, rolename	VARCHAR(50) NOT NULL
	, PRIMARY KEY ( username, rolename )
);

INSERT INTO `tRole` VALUES ( 1, 'Administrator', 'admin' );

DROP TABLE IF EXISTS `tUserConfig`;
CREATE TABLE `tUserConfig` (
	  user		VARCHAR(50) NOT NULL
	, cNamespace	VARCHAR(150) NOT NULL
	, cOption	VARCHAR(50) NOT NULL
	, cValue	BLOB

	, FOREIGN KEY ( user ) REFERENCES tUser.username ON DELETE CASCADE
);

DROP PROCEDURE IF EXISTS p_UserConfigUpdate;

DELIMITER //
CREATE PROCEDURE p_UserConfigUpdate (
	  IN c_user VARCHAR(100)
	, IN c_namespace VARCHAR(100)
	, IN c_option VARCHAR(100)
	, IN c_value BLOB )
BEGIN
	DECLARE c INT UNSIGNED;

	SELECT COUNT(*) INTO c FROM tUserConfig a
		WHERE
		    a.user = c_user
		AND a.cNameSpace = c_namespace
		AND a.cOption = c_option
		AND a.cValue = c_value;

	IF c > 0 THEN
		# Update
		UPDATE tUserConfig SET cValue = c_value
			WHERE user = c_user
			  AND cNameSpace = c_namespace
			  AND cOption = c_option;
	ELSE
		# Insert
		INSERT INTO tUserConfig (
				  user
				, cNamespace
				, cOption
				, cValue
			) VALUES (
				  c_user
				, c_namespace
				, c_option
				, c_value
			);
	END IF;
END//
DELIMITER ;

DROP TABLE IF EXISTS `tPayload`;
CREATE TABLE `tPayload` (
	  id			SERIAL
	, insert_stamp		TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
	, user			VARCHAR(50) NOT NULL
	, payload		BLOB
	, renderPlugin		VARCHAR(100) NOT NULL
	, renderOption		VARCHAR(100) NOT NULL
	, transmissionPlugin	VARCHAR(100) NOT NULL
);

##### Processor Tables #####

DROP TABLE IF EXISTS `tProcessor`;
CREATE TABLE `tProcessor` (
	  id		SERIAL
	, threadId	INT UNSIGNED NOT NULL DEFAULT 0
	, payloadId	INT UNSIGNED NOT NULL
	, stage		ENUM ( 'validation', 'render', 'translation', 'transmission' )
	, plugin	VARCHAR (100) NOT NULL
	, tsStart	TIMESTAMP NULL DEFAULT NULL
	, tsEnd		TIMESTAMP NULL DEFAULT NULL
	, pInput	BLOB
	, pOutput	BLOB

	, FOREIGN KEY ( payloadId ) REFERENCES tPayload.id ON DELETE CASCADE
);

DROP TABLE IF EXISTS `tThreadState`;
CREATE TABLE `tThreadState` (
	  threadId	INT UNSIGNED NOT NULL UNIQUE
	, processorId	INT UNSIGNED DEFAULT NULL
);

DROP TABLE IF EXISTS `tOutput`;
CREATE TABLE `tOutput` (
	  id		SERIAL
	, tsCreated	TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	, payloadId	INT UNSIGNED NOT NULL
	, processorId	INT UNSIGNED NOT NULL
	, filename	VARCHAR(150) NOT NULL
	, filesize	INT UNSIGNED NOT NULL DEFAULT 0

	, FOREIGN KEY ( payloadId ) REFERENCES tPayload.id ON DELETE CASCADE
	, FOREIGN KEY ( processorId ) REFERENCES tProcessor.id ON DELETE CASCADE
);

### Translation Lookup ###

DROP TABLE IF EXISTS `tTranslation`;
CREATE TABLE `tTranslation` (
	  plugin	VARCHAR( 100 ) NOT NULL
	, inputFormat	VARCHAR( 100 ) NOT NULL
	, outputFormat	VARCHAR( 100 ) NOT NULL
);

INSERT INTO `tTranslation` VALUES
	  ( 'org.remitt.plugin.translation.FixedFormPdf', 'fixedformxml', 'pdf' )
	, ( 'org.remitt.plugin.translation.FixedFormXml', 'fixedformxml', 'text' )
;
