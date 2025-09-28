-- Grant necessary privileges for testing
GRANT ALL PRIVILEGES ON *.* TO 'app'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- Create the test database
CREATE DATABASE IF NOT EXISTS exertion_test;
GRANT ALL PRIVILEGES ON exertion_test.* TO 'app'@'%';
FLUSH PRIVILEGES;
