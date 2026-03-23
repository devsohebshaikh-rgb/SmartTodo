-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 18, 2026 at 01:56 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `smart_todo`
--

-- --------------------------------------------------------

--
-- Table structure for table `locations`
--

CREATE TABLE `locations` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `city` varchar(255) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `address` text DEFAULT NULL,
  `visit_date` date DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `locations`
--

INSERT INTO `locations` (`id`, `user_id`, `city`, `latitude`, `longitude`, `address`, `visit_date`, `created_at`) VALUES
(1, 1, 'Pune', 18.52040000, 73.85670000, 'Shivajinagar, Pune, Maharashtra 411005', '2026-04-10', '2026-03-16 13:54:12'),
(2, 1, 'Mumbai', 19.07600000, 72.87770000, 'Colaba Causeway, Mumbai, Maharashtra 400005', '2026-04-18', '2026-03-16 13:54:12'),
(3, 1, 'Delhi', 28.61390000, 77.20900000, 'Connaught Place, New Delhi, Delhi 110001', '2026-05-02', '2026-03-16 13:54:12'),
(4, 1, 'Kolhapur', 13.94380746, 78.20955198, '', '2026-03-18', '2026-03-18 07:31:40');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `todo_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `triggered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('sent','read','dismissed') DEFAULT 'sent'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `todo_id`, `user_id`, `message`, `triggered_at`, `status`) VALUES
(1, 3, 1, 'You are near FC Road, Pune! Don\'t forget to meet Rahul at Vohuman Cafe.', '2026-03-16 13:54:12', 'sent'),
(2, 9, 1, 'Reminder: You have a document pickup at the embassy in Delhi.', '2026-03-16 13:54:12', 'read');

-- --------------------------------------------------------

--
-- Table structure for table `todos`
--

CREATE TABLE `todos` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `location_id` int(11) NOT NULL,
  `task_title` varchar(255) NOT NULL,
  `task_description` text DEFAULT NULL,
  `reminder_radius` int(11) DEFAULT 700,
  `status` enum('pending','in_progress','completed','missed') DEFAULT 'pending',
  `is_reminded` tinyint(4) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `todos`
--

INSERT INTO `todos` (`id`, `user_id`, `location_id`, `task_title`, `task_description`, `reminder_radius`, `status`, `is_reminded`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Visit Aga Khan Palace', 'Explore the historical palace and museum.', 500, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(2, 1, 1, 'Buy electronics from MG Road', 'Pick up USB-C hub and external SSD.', 300, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(3, 1, 1, 'Meet college friend', 'Catch up with Rahul at Vohuman Cafe, FC Road.', 700, 'in_progress', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(4, 1, 2, 'Client meeting at BKC', 'Present Q2 roadmap to the client team.', 1000, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(5, 1, 2, 'Pick up parcel from courier', 'Collect Amazon return parcel from BlueDart office.', 400, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(6, 1, 2, 'Dinner at Marine Drive', 'Try the new seafood restaurant near Nariman Point.', 600, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(7, 1, 3, 'Visit India Gate', 'Morning walk and photos at India Gate.', 800, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(8, 1, 3, 'Shopping at Sarojini Nagar', 'Buy winter clothes before the sale ends.', 500, 'pending', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(9, 1, 3, 'Document pickup from embassy', 'Collect attested documents from the embassy office.', 200, 'in_progress', 0, '2026-03-16 13:54:12', '2026-03-16 13:54:12'),
(10, 1, 4, 'Visit AR Patil Doctor', 'Doctors appointment', 700, 'completed', 0, '2026-03-18 07:31:40', '2026-03-18 07:37:17');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `created_at`, `updated_at`) VALUES
(1, 'Demo User', 'demo@demo.com', '$2a$10$KRqzJl6jjXGITPotFH3xyO5fXo7Soai0KPpTfWgBzsYGQHy3LAmy.', '2026-03-16 13:54:11', '2026-03-16 13:54:11');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_locations_user_id` (`user_id`),
  ADD KEY `idx_locations_visit_date` (`visit_date`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notifications_user_id` (`user_id`),
  ADD KEY `idx_notifications_todo_id` (`todo_id`),
  ADD KEY `idx_notifications_status` (`status`);

--
-- Indexes for table `todos`
--
ALTER TABLE `todos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_todos_user_id` (`user_id`),
  ADD KEY `idx_todos_location_id` (`location_id`),
  ADD KEY `idx_todos_status` (`status`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `locations`
--
ALTER TABLE `locations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `todos`
--
ALTER TABLE `todos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `locations`
--
ALTER TABLE `locations`
  ADD CONSTRAINT `fk_locations_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notifications_todo` FOREIGN KEY (`todo_id`) REFERENCES `todos` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `todos`
--
ALTER TABLE `todos`
  ADD CONSTRAINT `fk_todos_location` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_todos_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
