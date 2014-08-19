-- you must define an appropriate database
-- zazzle order database
-- 'id'	    = 'hanson'
-- 'secret' = '3f9bf3904b4e6609d46ff6964d8193ac'

-- ORDERS TABLE
USE `zazzle_store`;

DROP TABLE IF EXISTS `zazzle_orders`;
CREATE TABLE zazzle_orders (
id			INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
orderid			VARCHAR(255) UNIQUE,
order_date		VARCHAR(127),
method			VARCHAR(127),
priority		VARCHAR(127),
status			VARCHAR(127),
packing_sheet		VARCHAR(255),
shipto_address1		VARCHAR(127),
shipto_address2		VARCHAR(127),
shipto_address3		VARCHAR(127),
shipto_name		VARCHAR(127),
shipto_name2		VARCHAR(127),
shipto_city		VARCHAR(127),
shipto_state		VARCHAR(127),
shipto_country		VARCHAR(127),
shipto_country_code	VARCHAR(5),
shipto_zip		VARCHAR(127),
shipto_phone		VARCHAR(127),
shipto_email		VARCHAR(127),
shipto_type		VARCHAR(127)),
archived		INT NOT NULL DEFAULT 0;

-- ITEMS TABLE
DROP TABLE IF EXISTS `zazzle_items`;
CREATE TABLE zazzle_items (
id			INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
orderid			VARCHAR(255),
line_item_id		VARCHAR(127),
line_item_type		VARCHAR(127),
quantity		VARCHAR(127),
description		VARCHAR(127),
attributes_string	VARCHAR(127));

-- MESSAGES TABLE
DROP TABLE IF EXISTS `zazzle_messages`;
CREATE TABLE zazzle_messages (
id			INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
orderid			VARCHAR(255),
text			VARCHAR(255),
message_date		VARCHAR(255));

-- LABELS TABLE
DROP TABLE IF EXISTS `zazzle_labels`;
CREATE TABLE zazzle_labels (
id			INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
orderid			VARCHAR(255),
carrier			VARCHAR(255),
method			VARCHAR(255),
tracking_number		VARCHAR(255),
weight			FLOAT(3,2),
type			VARCHAR(127),
format			VARCHAR(5),
url			VARCHAR(255));
