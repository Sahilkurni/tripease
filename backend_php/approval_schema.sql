ALTER TABLE hotels
  ADD COLUMN status ENUM('pending','approved','rejected') DEFAULT 'pending';

ALTER TABLE packages
  ADD COLUMN status ENUM('pending','approved','rejected') DEFAULT 'pending';

ALTER TABLE buses
  ADD COLUMN status ENUM('pending','approved','rejected') DEFAULT 'pending';
