--------------------------------------------------
SELECT *
FROM ..NashvilleHousing

--------------------------------------------------
--Standarize date format
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM ..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

	--Above didn't work
	ALTER TABLE NashvilleHousing
	ADD SaleDateConverted Date;
	UPDATE NashvilleHousing
	SET SaleDateConverted = CONVERT(Date, SaleDate)

--------------------------------------------------
--Populate missing property address data 
SELECT *
FROM ..NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT matchingParcelA.ParcelID, matchingParcelA.PropertyAddress, matchingParcelB.ParcelID, matchingParcelB.PropertyAddress
, ISNULL(matchingParcelA.PropertyAddress, matchingParcelB.PropertyAddress)
FROM ..NashvilleHousing matchingParcelA
JOIN ..NashvilleHousing matchingParcelB
	ON matchingParcelA.ParcelID = matchingParcelB.ParcelID
	AND matchingParcelA.[UniqueID ] <> matchingParcelB.[UniqueID ]
WHERE matchingParcelA.PropertyAddress is null

UPDATE matchingParcelA
SET PropertyAddress = ISNULL(matchingParcelA.PropertyAddress , matchingParcelB.PropertyAddress)
FROM ..NashvilleHousing matchingParcelA
JOIN ..NashvilleHousing matchingParcelB
	ON matchingParcelA.ParcelID = matchingParcelB.ParcelID
	AND matchingParcelA.[UniqueID ] <> matchingParcelB.[UniqueID ]
WHERE matchingParcelA.PropertyAddress is null

--------------------------------------------------
--Split property address into two separate cols using charindex
SELECT PropertyAddress
FROM ..NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM ..NashvilleHousing

	ALTER TABLE NashvilleHousing
	ADD PropertySplitAddress Nvarchar(255);
	UPDATE NashvilleHousing
	SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

	ALTER TABLE NashvilleHousing
	ADD PropertySplitCity Nvarchar(255);
	UPDATE NashvilleHousing
	SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM ..NashvilleHousing

--------------------------------------------------
--Split owner address into three separate cols using parsename --NOTE
															   --(parse default is '.' - need to be changed and parse works backwards)
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM ..NashvilleHousing

	ALTER TABLE NashvilleHousing
	ADD OwnerSplitAddress Nvarchar(255);
	UPDATE NashvilleHousing
	SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

	ALTER TABLE NashvilleHousing
	ADD OwnerSplitCity Nvarchar(255);
	UPDATE NashvilleHousing
	SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

	ALTER TABLE NashvilleHousing
	ADD OwnerSplitState Nvarchar(255);
	UPDATE NashvilleHousing
	SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM ..NashvilleHousing

--------------------------------------------------
--Change Y and N to Yes and No
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM ..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 desc

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
  END as FixedValues
FROM ..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

--------------------------------------------------
--Remove duplicates using  OVER PRATITION BY and CTE
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
				 ) row_num
FROM ..NashvilleHousing
)
--DELETE
--FROM RowNumCTE
--WHERE row_num > 1
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--------------------------------------------------
--Delete unused columns
SELECT *
FROM ..NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress