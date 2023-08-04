-- El objetivo de este archivo SQL es realizar un Data Cleaning a la tabla de datos dataclean.
-- Se normalizará la base de datos. Se crearán nuevas tablas que se relacionen a través de los datos existentes con llaves fk, y que hagan que la información sea más accesible

-- Inspeccion básica

SELECT * FROM holamundo.datacleanpj;

-- La columna PropertyAddress posee más información de la necesaria (es un compuesto de la calle y el estado en el que esta ubicada). Será separada en dos: 1-PropertyStreetAddress, 2-PropertyCity

-- Extracción de la primera parte de la dirección hasta el separador ,

SELECT SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress) -1) AS PropertyStreetAddress
FROM datacleanpj;

-- Extracción de la segunda parte después del separador ,

SELECT SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) +1, LENGTH(PropertyAddress)) AS PropertyCity
FROM datacleanpj;

-- Alterar la tabla para crear dos nuevas columnas, y posteriormente insertar los Select Substring

ALTER TABLE datacleanpj 
ADD property_address VARCHAR(255);

UPDATE datacleanpj
SET property_address = SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress) -1);


ALTER TABLE datacleanpj
ADD property_city VARCHAR(255);

UPDATE datacleanpj
SET property_city = SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) +1, LENGTH(PropertyAddress));

SELECT * FROM datacleanpj 
LIMIT 1000;

-- Ahora es momento de eliminar la columna original de PropertyAddress para evitar redundancia

-- La columna OwnerAddress posee más información de la deseable. Hay que separar la calle, la ciudad y el estado en tres columnas diferentes

SELECT
  OwnerAddress,
  SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerAddress,
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) AS OwnerCity,
  SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -1), ',', 1) AS OwnerState
FROM
  datacleanpj;
  
-- Alter table para añadir nuevas columnas ownerstaddress, ownercity, ownerstate, y update los substring en la que corresponda

ALTER TABLE datacleanpj
ADD ownerstaddress VARCHAR(255);

UPDATE datacleanpj
SET ownerstaddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE datacleanpj
ADD ownercity VARCHAR(255);

UPDATE datacleanpj
SET ownercity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1);

ALTER TABLE datacleanpj
ADD ownerstate VARCHAR(255);

UPDATE datacleanpj
SET ownerstate = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -1), ',', 1);

-- Select para comprobar que todo este bien

SELECT * FROM datacleanpj
LIMIT 1000;

-- Llego el momento de separar las columnas en nuevas tablas que se relacionen entre sí. Esto facilitará la exploración de los datos
-- Dividiré la información en 3 tablas: sales_info que será la tabla principal, owner_info, y property_info
-- sales_info se relacionará con owner_info a través de un id Foreing Key llamado owner_id, y con property_info lo mismo pero la columna tendrá por nombre property_id

-- Primero crearé la tabla owner_id

CREATE TABLE owner_info (
	owner_id INT AUTO_INCREMENT PRIMARY KEY,
    owner_name VARCHAR(255),
    ownerstaddress VARCHAR(255),
    ownercity VARCHAR(255),
    ownerstate VARCHAR(255))
    AUTO_INCREMENT = 7000;
    

INSERT INTO owner_info (owner_name, ownerstaddress, ownercity, ownerstate)
SELECT OwnerName, ownerstaddress, ownercity, ownerstate FROM datacleanpj LIMIT 1000;

SELECT * FROM owner_info;

-- Ahora se repite el proceso con property_info
DROP TABLE IF EXISTS property_info;

CREATE TABLE property_info (
	property_id INT auto_increment PRIMARY KEY,
    owner_id INT,
    property_address VARCHAR(255),
    property_city VARCHAR(255),
    building_value VARCHAR(255),
    total_value VARCHAR(255),
    land_value VARCHAR(255),
    year_built VARCHAR(255),
    bedrooms VARCHAR(50),
    full_bath VARCHAR(50),
    half_bath VARCHAR(50))
    AUTO_INCREMENT = 4100;
    
ALTER TABLE property_info
ADD FOREIGN KEY (owner_id) REFERENCES owner_info(owner_id);

INSERT INTO property_info (owner_id, property_address, property_city, building_value, total_value, land_value, year_built, bedrooms, full_bath, half_bath)
SELECT 
    oi.owner_id, 
    dc.property_address, 
    dc.property_city, 
    dc.BuildingValue, 
    dc.TotalValue, 
    dc.LandValue, 
    dc.YearBuilt, 
    dc.Bedrooms, 
    dc.FullBath, 
    dc.HalfBath 
FROM 
    owner_info AS oi
JOIN 
    datacleanpj AS dc 
ON 
    oi.ownerstate = dc.ownerstate
    LIMIT 1000;
    
SELECT * FROM property_info;

-- La mayoría de los datos hay que convertirlos a otro tipo con clausula CAST o Convert, pero ya se encuentran en la tabla

-- Ultima tabla sales_info
DROP TABLE IF EXISTS sales_info;

CREATE TABLE sales_info (
	sale_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT,
    owner_id INT,
    sale_price VARCHAR(255))
    AUTO_INCREMENT = 6050;
    
ALTER TABLE sales_info
ADD FOREIGN KEY (property_id) REFERENCES property_info(property_id);

ALTER TABLE sales_info
ADD FOREIGN KEY (owner_id) REFERENCES owner_info(owner_id);

INSERT INTO sales_info (property_id, owner_id, sale_price)
SELECT p.property_id, o.owner_id, dc.SalePrice FROM property_info AS p
JOIN owner_info o ON o.owner_id = p.owner_id
JOIN datacleanpj dc ON dc.ownerstaddress = o.ownerstaddress
LIMIT 1000;

SELECT * FROM sales_info;

-- Limite el Insert a 1000 por objetivos del proyecto. La intención del mismo era demostrar un proceso básico de limpieza de datos, y con esta nueva estructura queda completado
-- ¡Gracias por leer!