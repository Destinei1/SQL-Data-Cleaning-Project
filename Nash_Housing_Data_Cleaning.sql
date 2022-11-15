/* 
Cleaning data in SQL Queries
*/

SELECT * 
FROM dbo.NashHousing

-- standardize salesDate

SELECT saleDate
		, CONVERT(Date, SaleDate)
FROM dbo.NashHousing

/*  for some reason the update statement didnt work on the original column
	, so we try alter to make a new column then update the new column 
	and delete the old at the end

UPDATE NashHousing
SET SaleDate = CONVERT(DATE, SaleDate)

*/

ALTER TABLE NashHousing
Add SaleDateConvert Date;

UPDATE NashHousing
SET SaleDateConvert = CONVERT(DATE, SaleDate)


--- Populate the Propert Address Data

SELECT propertyAddress
FROM dbo.NashHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

/* we know from reviewing the table that some properties
	have the same ParcelID, we can use that info to fill in
	the blanks. We create a query that self joins the table to
	look for records with the same parcelID, not not the same
	unique id. We took that query (from FROM to the end of the JOIN)
	and used it for the update statement
*/

SELECT n1.ParcelID
		, n1.propertyAddress
		, n2.ParcelID
		, n2.propertyAddress
		, ISNULL(n1.propertyAddress, n2.propertyAddress)
FROM dbo.NashHousing n1
JOIN dbo.NashHousing n2 ON n1.ParcelID = n2.ParcelID
							AND n1.[UniqueID ] <> n2.[UniqueID ]
WHERE n1.PropertyAddress IS NULL

UPDATE n1
SET PropertyAddress = ISNULL(n1.propertyAddress, n2.propertyAddress)
FROM dbo.NashHousing n1
JOIN dbo.NashHousing n2 ON n1.ParcelID = n2.ParcelID
							AND n1.[UniqueID ] <> n2.[UniqueID ]
WHERE n1.PropertyAddress IS NULL

-- split address columns
SELECT SUBSTRING(propertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address
	, SUBSTRING(propertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM dbo.NashHousing

ALTER TABLE NashHousing
Add PropertySplitAddress nvarchar(255);

UPDATE NashHousing
SET PropertySplitAddress = SUBSTRING(propertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashHousing
Add PropertySplitCity nvarchar(255);

UPDATE NashHousing
SET PropertySplitCity = SUBSTRING(propertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT * 
FROM dbo.NashHousing

-- OWNER ADDRESS

SELECT OwnerAddress
		, PARSENAME(REPLACE(OwnerAddress, ',','.') , 1)
		, PARSENAME(REPLACE(OwnerAddress, ',','.') , 2)
		, PARSENAME(REPLACE(OwnerAddress, ',','.') , 3)
FROM dbo.NashHousing

ALTER TABLE NashHousing
Add OwnerAddStreetSplit nvarchar(255);

ALTER TABLE NashHousing
Add OwnerAddCitySplit nvarchar(255);

ALTER TABLE NashHousing
Add OwnerAddStateSplit nvarchar(255);

UPDATE NashHousing
SET OwnerAddStreetSplit = PARSENAME(REPLACE(OwnerAddress, ',','.') , 3)

UPDATE NashHousing
SET OwnerAddCitySplit = PARSENAME(REPLACE(OwnerAddress, ',','.') , 2)

UPDATE NashHousing
SET OwnerAddStateSplit = PARSENAME(REPLACE(OwnerAddress, ',','.') , 1)

-- Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SoldAsVacant)
FROM NashHousing

SELECT SoldAsVacant
		, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			   WHEN SoldAsVacant = 'N' THEN 'No'
			   ELSE SoldAsVacant END AS new_col
FROM NashHousing

UPDATE NashHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			   WHEN SoldAsVacant = 'N' THEN 'No'
			   ELSE SoldAsVacant END


-- Remove Duplicates
WITH RowNumCTE AS (
SELECT *
	, ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
						 PropertyAddress,
						 SalePrice,
						 SaleDate,
						 LegalReference
						 ORDER BY UniqueID) row_num
FROM NashHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


-- Delete unused columns, Columns we've already split

ALTER TABLE NashHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashHousing
DROP COLUMN SaleDate
