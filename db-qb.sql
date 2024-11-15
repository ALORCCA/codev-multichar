CREATE TABLE IF NOT EXISTS `codev_multichar_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(50) DEFAULT NULL,
  `used` int(11) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=UTF8_GENERAL_CI;

CREATE TABLE IF NOT EXISTS `codev_multichar` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(90) DEFAULT NULL,
  `uses` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;