CREATE DATABASE direction;

USE direction;

CREATE TABLE user (
    `id` INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `age` INT(5),
    `sex` VARCHAR(5),
    `is_deleted` INT(1) NOT NULL,  
    `created_at` TIMESTAMP NOT NULL, 
    `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW()
);

CREATE TABLE time_slice (
    `id` INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `desc` VARCHAR(200),
    `is_deleted` INT(1) NOT NULL,  
    `created_at` TIMESTAMP NOT NULL, 
    `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW()
);

CREATE TABLE frequencies (
    `id` INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `desc` VARCHAR(200),
    `is_deleted` INT(1) NOT NULL,  
    `created_at` TIMESTAMP NOT NULL, 
    `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW()
);

CREATE TABLE movement (
    `id` INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `desc` VARCHAR(200),
    `is_deleted` INT(1) NOT NULL,  
    `created_at` TIMESTAMP NOT NULL, 
    `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW()
);

CREATE TABLE active_pass (
    `id` INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL,
    `desc` VARCHAR(200),
    `is_deleted` INT(1) NOT NULL,  
    `created_at` TIMESTAMP NOT NULL, 
    `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW()
);

CREATE TABLE readings (
    `id` INT(6) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT(5) NOT NULL,
    `time_slice_id` INT(5) NOT NULL,
    `frequency_id` INT(5) NOT NULL,
    `active_pass_id` INT(5) NOT NULL,
    `movement_id` INT(5) NOT NULL,
    `accuracy` INT(5) NOT NULL,
    `is_deleted` INT(1) NOT NULL,  
    `created_at` TIMESTAMP NOT NULL, 
    `updated_at` TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW()
);

INSERT INTO active_pass (`name`, `is_deleted`) VALUES ('active', 0), ('passive', 0);
INSERT INTO frequencies (`name`, `is_deleted`) VALUES ('Alpha', 0), ('Beta', 0), ('Delta', 0), ('Theta', 0);
INSERT INTO movement (`name`, `is_deleted`) VALUES ('Left/Right', 0), ('Up/Down', 0), ('In/Out', 0);
INSERT INTO time_slice (`name`, `is_deleted`) VALUES ('-0.3 to 0', 0), ('-0.3 to 0.3', 0), ('0 to 0.5', 0), ('0 to 1', 0), ('0 to 2', 0);