CREATE TABLE IF NOT EXISTS `factories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `factory_name` varchar(255) NOT NULL,
  `localisation` varchar(255) DEFAULT NULL,
  `fiscal_matricule` varchar(255) NOT NULL,
  `energy_capacity` int DEFAULT NULL,
  `contact_info` varchar(255) DEFAULT NULL,
  `energy_source` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `fiscal_matricule` (`fiscal_matricule`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
