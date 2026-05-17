IF DB_ID('Trash2Cash') IS NULL
BEGIN
  CREATE DATABASE Trash2Cash;
END
GO

USE Trash2Cash;
GO

CREATE TABLE Plans (
  plan_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(120) NOT NULL UNIQUE,
  monthly_bag_limit INT NOT NULL CHECK (monthly_bag_limit > 0),
  max_weight_per_bag DECIMAL(10,2) NOT NULL CHECK (max_weight_per_bag > 0),
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  bonus_percentage DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (bonus_percentage >= 0),
  benefits NVARCHAR(MAX) NULL,
  is_active BIT NOT NULL DEFAULT 1,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Users (
  user_id INT IDENTITY(1,1) PRIMARY KEY,
  full_name NVARCHAR(160) NOT NULL,
  email NVARCHAR(255) NOT NULL UNIQUE,
  phone NVARCHAR(40) NOT NULL,
  address NVARCHAR(500) NOT NULL,
  password_hash NVARCHAR(255) NOT NULL,
  role NVARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  plan_id INT NULL,
  total_points INT NOT NULL DEFAULT 0,
  status NVARCHAR(40) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Users_Plans FOREIGN KEY (plan_id) REFERENCES Plans(plan_id)
);
GO

CREATE TABLE Categories (
  category_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(120) NOT NULL UNIQUE,
  points_per_kg DECIMAL(10,2) NOT NULL CHECK (points_per_kg >= 0),
  is_active BIT NOT NULL DEFAULT 1,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Bags (
  bag_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  total_weight DECIMAL(10,2) NOT NULL CHECK (total_weight > 0),
  total_points INT NOT NULL CHECK (total_points >= 0),
  status NVARCHAR(40) NOT NULL DEFAULT 'submitted',
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Bags_Users FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

CREATE TABLE Bag_Items (
  item_id INT IDENTITY(1,1) PRIMARY KEY,
  bag_id INT NOT NULL,
  category_id INT NOT NULL,
  weight DECIMAL(10,2) NOT NULL CHECK (weight > 0),
  earned_points INT NOT NULL CHECK (earned_points >= 0),
  CONSTRAINT FK_BagItems_Bags FOREIGN KEY (bag_id) REFERENCES Bags(bag_id) ON DELETE CASCADE,
  CONSTRAINT FK_BagItems_Categories FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);
GO

CREATE TABLE Trucks (
  truck_id INT IDENTITY(1,1) PRIMARY KEY,
  plate_number NVARCHAR(40) NOT NULL UNIQUE,
  driver_name NVARCHAR(160) NOT NULL,
  current_status NVARCHAR(40) NOT NULL DEFAULT 'available',
  current_area NVARCHAR(160) NULL,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Service_Areas (
  area_id INT IDENTITY(1,1) PRIMARY KEY,
  area_name NVARCHAR(160) NOT NULL,
  city NVARCHAR(120) NOT NULL,
  is_active BIT NOT NULL DEFAULT 1,
  delivery_fee DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0),
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT UQ_ServiceAreas_NameCity UNIQUE (area_name, city)
);
GO

CREATE TABLE Truck_Areas (
  id INT IDENTITY(1,1) PRIMARY KEY,
  truck_id INT NOT NULL,
  area_id INT NOT NULL,
  CONSTRAINT FK_TruckAreas_Trucks FOREIGN KEY (truck_id) REFERENCES Trucks(truck_id) ON DELETE CASCADE,
  CONSTRAINT FK_TruckAreas_Areas FOREIGN KEY (area_id) REFERENCES Service_Areas(area_id) ON DELETE CASCADE,
  CONSTRAINT UQ_TruckAreas UNIQUE (truck_id, area_id)
);
GO

CREATE TABLE Bookings (
  booking_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  truck_id INT NULL,
  area_id INT NULL,
  pickup_date DATE NOT NULL,
  pickup_time VARCHAR(8) NOT NULL,
  address NVARCHAR(500) NOT NULL,
  status NVARCHAR(40) NOT NULL DEFAULT 'scheduled',
  estimated_arrival NVARCHAR(80) NULL,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Bookings_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
  CONSTRAINT FK_Bookings_Trucks FOREIGN KEY (truck_id) REFERENCES Trucks(truck_id),
  CONSTRAINT FK_Bookings_Areas FOREIGN KEY (area_id) REFERENCES Service_Areas(area_id)
);
GO

CREATE TABLE Rewards_History (
  reward_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  points INT NOT NULL,
  reason NVARCHAR(255) NOT NULL,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Rewards_Users FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

CREATE TABLE Payments (
  payment_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  plan_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  currency NVARCHAR(10) NOT NULL DEFAULT 'EGP',
  payment_method NVARCHAR(40) NOT NULL DEFAULT 'card',
  card_last4 NVARCHAR(4) NULL,
  cardholder_name NVARCHAR(160) NULL,
  status NVARCHAR(40) NOT NULL DEFAULT 'completed',
  transaction_reference NVARCHAR(120) NOT NULL UNIQUE,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Payments_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
  CONSTRAINT FK_Payments_Plans FOREIGN KEY (plan_id) REFERENCES Plans(plan_id)
);
GO

CREATE TABLE Subscriptions (
  subscription_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  plan_id INT NOT NULL,
  payment_id INT NULL,
  status NVARCHAR(40) NOT NULL DEFAULT 'active',
  started_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  ended_at DATETIME2 NULL,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Subscriptions_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
  CONSTRAINT FK_Subscriptions_Plans FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
  CONSTRAINT FK_Subscriptions_Payments FOREIGN KEY (payment_id) REFERENCES Payments(payment_id)
);
GO

CREATE TABLE Partners (
  partner_id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(160) NOT NULL UNIQUE,
  description NVARCHAR(500) NOT NULL,
  category NVARCHAR(120) NOT NULL,
  logo_url NVARCHAR(500) NULL,
  contact_email NVARCHAR(255) NULL,
  phone NVARCHAR(40) NULL,
  is_active BIT NOT NULL DEFAULT 1,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Partner_Offers (
  offer_id INT IDENTITY(1,1) PRIMARY KEY,
  partner_id INT NOT NULL,
  title NVARCHAR(160) NOT NULL,
  description NVARCHAR(500) NOT NULL,
  points_required INT NOT NULL CHECK (points_required > 0),
  discount_type NVARCHAR(60) NOT NULL,
  discount_value DECIMAL(10,2) NULL,
  coupon_code NVARCHAR(120) NULL,
  expiry_date DATE NULL,
  is_active BIT NOT NULL DEFAULT 1,
  CONSTRAINT FK_PartnerOffers_Partners FOREIGN KEY (partner_id) REFERENCES Partners(partner_id) ON DELETE CASCADE
);
GO

CREATE TABLE Redemptions (
  redemption_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  offer_id INT NOT NULL,
  points_used INT NOT NULL CHECK (points_used > 0),
  redeemed_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  status NVARCHAR(40) NOT NULL DEFAULT 'confirmed',
  CONSTRAINT FK_Redemptions_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
  CONSTRAINT FK_Redemptions_Offers FOREIGN KEY (offer_id) REFERENCES Partner_Offers(offer_id)
);
GO

CREATE TABLE Achievements (
  achievement_id INT IDENTITY(1,1) PRIMARY KEY,
  title NVARCHAR(160) NOT NULL,
  description NVARCHAR(500) NOT NULL
);
GO

CREATE TABLE User_Achievements (
  id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  achievement_id INT NOT NULL,
  earned_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_UserAchievements_Users FOREIGN KEY (user_id) REFERENCES Users(user_id),
  CONSTRAINT FK_UserAchievements_Achievements FOREIGN KEY (achievement_id) REFERENCES Achievements(achievement_id),
  CONSTRAINT UQ_UserAchievement UNIQUE (user_id, achievement_id)
);
GO

CREATE TABLE Referrals (
  referral_id INT IDENTITY(1,1) PRIMARY KEY,
  referrer_user_id INT NOT NULL,
  referred_user_id INT NOT NULL,
  referral_code NVARCHAR(80) NOT NULL UNIQUE,
  reward_points INT NOT NULL DEFAULT 0,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Referrals_Referrer FOREIGN KEY (referrer_user_id) REFERENCES Users(user_id),
  CONSTRAINT FK_Referrals_Referred FOREIGN KEY (referred_user_id) REFERENCES Users(user_id)
);
GO

CREATE TABLE Notifications (
  notification_id INT IDENTITY(1,1) PRIMARY KEY,
  user_id INT NOT NULL,
  title NVARCHAR(160) NOT NULL,
  message NVARCHAR(MAX) NOT NULL,
  type NVARCHAR(40) NOT NULL DEFAULT 'system',
  is_read BIT NOT NULL DEFAULT 0,
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  CONSTRAINT FK_Notifications_Users FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

CREATE TABLE System_Settings (
  setting_id INT IDENTITY(1,1) PRIMARY KEY,
  setting_key NVARCHAR(120) NOT NULL UNIQUE,
  setting_value NVARCHAR(MAX) NOT NULL,
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE INDEX IX_Bags_UserCreated ON Bags(user_id, created_at DESC);
CREATE INDEX IX_Bookings_UserDate ON Bookings(user_id, pickup_date DESC);
CREATE INDEX IX_Bookings_Status ON Bookings(status);
CREATE INDEX IX_Notifications_UserRead ON Notifications(user_id, is_read, created_at DESC);
CREATE INDEX IX_Payments_UserCreated ON Payments(user_id, created_at DESC);
CREATE INDEX IX_Subscriptions_UserStatusStarted ON Subscriptions(user_id, status, started_at DESC);
CREATE INDEX IX_PartnerOffers_PartnerActiveExpiry ON Partner_Offers(partner_id, is_active, expiry_date);
CREATE INDEX IX_Redemptions_UserRedeemed ON Redemptions(user_id, redeemed_at DESC);
CREATE INDEX IX_Redemptions_OfferStatus ON Redemptions(offer_id, status, redeemed_at DESC);
GO
