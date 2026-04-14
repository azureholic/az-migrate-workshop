CREATE USER webadmin WITH PASSWORD 'webadmin123';
CREATE DATABASE webapp OWNER webadmin;
GRANT pg_read_all_data TO webadmin;
GRANT pg_read_all_settings TO webadmin;
