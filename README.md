## Prison Management System
The Prison Management System (PMS) is a relational database application for a correctional facility.
It replaces paper registers and disconnected spreadsheets with one normalized, access-controlled
database that records inmates, blocks and cells, staff, court cases and sentences, visitors and visits,
medical records and incidents.
The system answers questions such as which inmate is in which cell, whose sentence ends in the next
30 days, which cells are over capacity, and who visited whom. It targets recurring problems: duplicate
inmate records, slow lookups of case and release information, overcrowding that goes unnoticed, no
audit trail of changes, and errors in release dates and visitor approvals.
The database has 14 tables (10 entities and 4 junction tables) with primary, foreign, UNIQUE, CHECK
and NOT NULL constraints, normalized to 3NF. It includes at least 15 queries, views, triggers, stored
procedures for admission, transfer and release, transactions, indexing, and role-based access for five
user roles. A Python Flask front end provides role-based login. Only synthetic data (at least 100 inmate
records) is used.
