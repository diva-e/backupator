SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- --------------------------------------------------------

--
-- Table structure for table `backups`
--

CREATE TABLE `backups` (
  `id` int NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dataset` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `storage_node` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `backup_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `present` tinyint NOT NULL,
  `status` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `verify_queue_id` int NOT NULL,
  `node_results` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
  `client_results` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `backups_archive`
--

CREATE TABLE `backups_archive` (
  `id` int NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dataset` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `storage_node` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `backup_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `present` tinyint NOT NULL,
  `status` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `verify_queue_id` int NOT NULL,
  `node_results` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `client_results` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `backup_verify_configs`
--

CREATE TABLE `backup_verify_configs` (
  `id` int NOT NULL,
  `name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `clients`
--

CREATE TABLE `clients` (
  `id` int NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dataset` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `friendly_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `fstype` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `destination` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `backup_interval` int NOT NULL,
  `lastrun` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `storage` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `replicator` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `active` tinyint NOT NULL,
  `verify` tinyint NOT NULL,
  `verify_template` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `backup_verify_config` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `backup_size` bigint NOT NULL,
  `snapshots_size` bigint NOT NULL,
  `snapshot_retention` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `config`
--

CREATE TABLE `config` (
  `id` int NOT NULL,
  `configkey` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `configvalue` smallint NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
--
-- Dumping data for table `config`
--

INSERT INTO `config` (`id`, `configkey`, `configvalue`, `description`) VALUES
(9, 'BACKUP_STALE_TIME', 30, 'This value is in MINUTES. How long should we wait for a server to pick up a backup type job.'),
(10, 'VERIFY_STALE_TIME', 60, 'This value is in MINUTES. How long should we wait for a verify job, before we mark it as stale/failed.'),
(12, 'JOB_STALE_TIME', 340, 'This value is in MINUTES. How long before we mark a job as Failed.'),
(15, 'VERIFICATION_ENABLED', 1, 'Whether verification should be performed after a backup or not. Allowed values are 1=Enabled, 0=Disabled.');

-- --------------------------------------------------------

--
-- Table structure for table `queue`
--

CREATE TABLE `queue` (
  `id` int NOT NULL,
  `type` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dataset` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `storage_node` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `scheduled` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `started` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ended` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `comment` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `queue_archive`
--

CREATE TABLE `queue_archive` (
  `id` int NOT NULL,
  `type` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dataset` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `storage_node` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `scheduled` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `started` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ended` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `comment` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `queue_test`
--

CREATE TABLE `queue_test` (
  `id` int NOT NULL,
  `type` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dataset` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `storage_node` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `scheduled` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `started` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ended` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `status` varchar(9) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `comment` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `storage_nodes`
--

CREATE TABLE `storage_nodes` (
  `id` int NOT NULL,
  `hostname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `ip` varchar(15) COLLATE utf8mb4_bin NOT NULL,
  `lastschedule` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `active` int NOT NULL,
  `pool` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `storage_path` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `replication_enabled` tinyint NOT NULL,
  `used_space` bigint NOT NULL,
  `free_space` bigint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `uilog`
--

CREATE TABLE `uilog` (
  `id` int NOT NULL,
  `username` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `action` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `time` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Table structure for table `verify_queries`
--

CREATE TABLE `verify_queries` (
  `id` int NOT NULL,
  `query` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `template` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `backups`
--
ALTER TABLE `backups`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `backups_archive`
--
ALTER TABLE `backups_archive`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `backup_verify_configs`
--
ALTER TABLE `backup_verify_configs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `clients`
--
ALTER TABLE `clients`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `config`
--
ALTER TABLE `config`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `queue`
--
ALTER TABLE `queue`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `queue_archive`
--
ALTER TABLE `queue_archive`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `queue_test`
--
ALTER TABLE `queue_test`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `storage_nodes`
--
ALTER TABLE `storage_nodes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `uilog`
--
ALTER TABLE `uilog`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `verify_queries`
--
ALTER TABLE `verify_queries`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `backups`
--
ALTER TABLE `backups`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `backups_archive`
--
ALTER TABLE `backups_archive`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `backup_verify_configs`
--
ALTER TABLE `backup_verify_configs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `clients`
--
ALTER TABLE `clients`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `config`
--
ALTER TABLE `config`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `queue`
--
ALTER TABLE `queue`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `queue_archive`
--
ALTER TABLE `queue_archive`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `queue_test`
--
ALTER TABLE `queue_test`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `storage_nodes`
--
ALTER TABLE `storage_nodes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `uilog`
--
ALTER TABLE `uilog`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `verify_queries`
--
ALTER TABLE `verify_queries`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
