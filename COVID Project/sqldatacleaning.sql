
/*
Cleaning Data in SQL Queries
*/

Select *
from NashvilleHousing

-- Standardize Date Format
select SaleDate, CONVERT(Date,SaleDate) from NashvilleHousing

update NashvilleHousing
SET SaleDate=CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

update NashvilleHousing
SET SaleDateConverted=CONVERT(Date,SaleDate)

-- Populate Property Address data
Select *
FROM NashvilleHousing
Where PropertyAddress IS NULL


Select a.ParcelID, a.PropertyAddress,b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b ON a.ParcelID=b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL

update a 
SET PropertyAddress=ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM NashvilleHousing a
JOIN NashvilleHousing b ON a.ParcelID=b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL


-- Breaking out Address into Individual Columns (Address, City State)
select PropertyAddress from PortfolioProject.dbo.NashvilleHousing

select
Substring(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1) as Address,
Substring(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))  as Address
from PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = Substring(PropertyAddress,1, CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity Nvarchar(255)

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity= Substring(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

select * FROM PortfolioProject.dbo.NashvilleHousing


select OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing


select PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from PortfolioProject.dbo.NashvilleHousing



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)
Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)
Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity= PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255)
Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState= PARSENAME(REPLACE(OwnerAddress,',','.'),1)


-- Change Y and N to Yes and No in "Sold as Vacant' field
select DISTINCT(SoldAsVacant), Count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant

select SoldAsVacant
, CASE WHEN SoldAsVacant='Y' THEN 'Yes'
	   WHEN SoldAsVacant='N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant='Y' THEN 'Yes'
	   WHEN SoldAsVacant='N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-- Remove Duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress








