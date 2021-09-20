
--- 1) DATA CLEANING
--- Identify Null Value

SELECT 
  SUM(CASE WHEN [Highest Charting Position] IS NULL THEN 1 ELSE 0 END)Highest_Charting_Position, 
  SUM(CASE WHEN [Number of Times Charted] IS NULL THEN 1 ELSE 0 END)Number_of_Times_Charted,
  SUM(CASE WHEN [Song Name] IS NULL THEN 1 ELSE 0 END)Song_Name,
  SUM(CASE WHEN Streams IS NULL THEN 1 ELSE 0 END)Streams,
  SUM(CASE WHEN Artist IS NULL THEN 1 ELSE 0 END)Artist,
  SUM(CASE WHEN [Artist Followers] IS NULL THEN 1 ELSE 0 END)Artist_Followers,
  SUM(CASE WHEN Genre IS NULL THEN 1 ELSE 0 END)Genre,
  SUM(CASE WHEN Popularity IS NULL THEN 1 ELSE 0 END)Popularity,
  SUM(CASE WHEN [Week of Highest Charting] IS NULL THEN 1 ELSE 0 END)Week_of_Highest_Charting
FROM master..spotify200$



--- Fill in Null Value in Artist Followers column by Populating Data 

SELECT a.Artist, a.[Artist Followers], b.Artist, b.[Artist Followers], ISNULL(a.[Artist Followers], b.[Artist Followers])
FROM master..spotify200$ a
JOIN master..spotify200$ b 
ON a.Artist = b.Artist
AND a.[Song Name] <> b.[Song Name]
WHERE a.[Artist Followers] IS NULL

UPDATE a
SET [Artist Followers] = ISNULL(a.[Artist Followers],b.[Artist Followers])
FROM master..spotify200$ a
JOIN master..spotify200$ b 
ON a.Artist = b.Artist
AND a.[Song Name] <> b.[Song Name]


--- Checking if there is any null values left in the Artist Followers column

SELECT Artist, [Artist Followers], [Song Name]
FROM master..spotify200$
WHERE [Artist Followers] IS NULL

--- Turns out there are still null values left for artists who only got listed once 
-- Replace the NULL values with the data from Spotify App
-- Chris Rae - 654062
-- Super Yei - 295238
-- Dalex - 3,673,189
-- AK AUSSERKONTROLLE, Bonez MC - 703,373

UPDATE master..spotify200$
SET 
    [Artist Followers] = 654062
WHERE
    Artist = 'Chris Rea'
 
UPDATE master..spotify200$
SET 
    [Artist Followers] = 295238
WHERE
    Artist = 'Super Yei, Jone Quest'

UPDATE master..spotify200$
SET 
    [Artist Followers] = 3673189
WHERE
    Artist = 'Dalex'

UPDATE master..spotify200$
SET 
    [Artist Followers] = 703373
WHERE
    Artist = 'AK AUSSERKONTROLLE, Bonez MC'



--- Fill in null values with 0 in the popularity column 

UPDATE master..spotify200$
SET 
    Popularity = 0
WHERE
    Popularity IS NULL



--- Identify Unique Values in Song Name 

SELECT Artist, [Artist Followers], [Song Name]
FROM master..spotify200$
WHERE [Song Name] LIKE '[#?]%' 


UPDATE master..spotify200$
SET 
    [Song Name] = 'Other'
WHERE
    [Song Name] LIKE '[#?]%' 

 

--- Split the Genre data into different columns and extract the first value 

SELECT Genre, 
LEFT(Genre, CHARINDEX(',', Genre)) AS Genre1
FROM master..spotify200$

UPDATE master..spotify200$
SET 
    Genre = LEFT(Genre, CHARINDEX(',', Genre))
 


--- Classify the Music Genre 

SELECT Genre, 
		 CASE 
		    WHEN Genre LIKE '%k-pop%' THEN 'Kpop music'
            WHEN Genre LIKE '%pop%' THEN 'Pop music'
            WHEN Genre LIKE '%country%' THEN 'Country music'
            WHEN Genre LIKE '%rap%' OR Genre LIKE '%hip hop%' OR Genre LIKE '%drill%' THEN 'Hip Hop music'
		    WHEN Genre LIKE '%soul%' THEN 'Soul music'
            WHEN Genre LIKE '%funk%' THEN 'Funk'
			WHEN Genre LIKE '%rock%' THEN 'Rock'
			WHEN Genre LIKE '%r&b%' THEN 'R&B'
            ELSE 'Other' 
		END AS Genre1
FROM master..spotify200$

--- Add Column 

ALTER TABLE master..spotify200$
ADD Genre1 VARCHAR(255)

UPDATE master..spotify200$
SET Genre1 = CASE 
	WHEN Genre LIKE '%k-pop%' THEN 'Kpop music'
	WHEN Genre LIKE '%pop%' THEN 'Pop music'
	WHEN Genre LIKE '%country%' THEN 'Country music'
	WHEN Genre LIKE '%rap%' OR Genre LIKE '%hip hop%' OR Genre LIKE '%drill%' THEN 'Hip Hop music'
	WHEN Genre LIKE '%soul%' THEN 'Soul music'
	WHEN Genre LIKE '%funk%' THEN 'Funk'
	WHEN Genre LIKE '%rock%' THEN 'Rock'
	WHEN Genre LIKE '%r&b' THEN 'R&B'
	ELSE 'Other'
END


		
--- Split the week of highest charting data into two columns and change the the datatype from varchar to date

SELECT [Week of Highest Charting],
	PARSENAME(REPLACE([Week of Highest Charting], '--','.'), 2) AS Start_week,
	PARSENAME(REPLACE([Week of Highest Charting], '--','.'), 1) AS End_week
FROM master..spotify200$

ALTER TABLE master..spotify200$
ADD Highest_Charting_Week DATE

UPDATE master..spotify200$
SET Highest_Charting_Week = PARSENAME(REPLACE([Week of Highest Charting], '--','.'), 1)


--- Split Artist Name column and only extract the first value 

SELECT Artist, 
LEFT(Artist, CHARINDEX(',', Artist)) AS Main_Artist
FROM master..spotify200$

SELECT Artist, 
		 CASE 
		    WHEN Artist LIKE '%,%' THEN LEFT(Artist, CHARINDEX(',', Artist) -1)
		ELSE Artist
END Main_Artist
FROM master..spotify200$

UPDATE master..spotify200$
SET Artist = CASE 
		    WHEN Artist LIKE '%,%' THEN LEFT(Artist, CHARINDEX(',', Artist) -1)
		ELSE Artist
		END


--- Delete Unused Column 

ALTER TABLE master..spotify200$
DROP COLUMN [Week of Highest Charting], [Song ID], Genre, [Release Date], [Weeks Charted], Danceability, Energy, Loudness, Speechiness, Acousticness, Liveness, Tempo, [Duration (ms)], Valence, Chord 



--- 2) Explore Data
--- Top 30 Most Popular Artist by Total Number of Times Charted  

SELECT DISTINCT TOP 30 Artist, SUM([Number of Times Charted]) AS Total_Number_of_Times_Charted
FROM master..spotify200$
GROUP BY Artist
ORDER BY Total_Number_of_Times_Charted DESC



--- Top 30 Artist by the Number of Artist Followers 
--- We will use JOIN clause to fetch the latest by Highest Charting Week for all the artist followers values.

SELECT TOP 30 a.Artist, a.Highest_Charting_Week, a.[Artist Followers]
FROM master..spotify200$ a
INNER JOIN (
    SELECT Artist, MAX(Highest_Charting_Week) as MaxDate
    FROM master..spotify200$
    GROUP BY Artist
) b ON a.Artist = b.Artist AND a.Highest_Charting_Week = b.MaxDate
GROUP BY a.Artist, a. Highest_Charting_Week, a.[Artist Followers]
ORDER BY [Artist Followers] DESC



--- Top 30 Song by the number of times charted 

SELECT TOP 30 [Song Name], SUM([Number of Times Charted]) AS Total_Number_of_Times_Charted
FROM master..spotify200$
GROUP BY [Song Name] 
ORDER BY Total_Number_of_Times_Charted DESC



--- Song by the highest position (flter by week)

SELECT [Song Name], [Highest Charting Position]
FROM master..spotify200$
WHERE Highest_Charting_Week = '2021-07-02'
ORDER BY [Highest Charting Position] ASC



--- Top 30 Song by stream

SELECT TOP 30 [Song Name], Artist, Streams
FROM master..spotify200$
ORDER BY Streams DESC



--- Classify Song based on Popularity
--- First, identify the mean, min, and max value in the popularity column 

SELECT AVG(Popularity) AS Mean, 
	   MIN(Popularity) AS Min,
	   MAX(Popularity) AS Max
FROM master..spotify200$

--- Then , classify them

SELECT Popularity,
  CASE 
		WHEN Popularity BETWEEN 0 AND 20 THEN 'Unpopular'
		WHEN Popularity BETWEEN 21 AND 30 THEN 'Least popular'
		WHEN Popularity BETWEEN 31 AND 50 THEN 'Moderate'
		WHEN Popularity BETWEEN 51 AND 70 THEN 'Relatively popular'
		WHEN Popularity BETWEEN 71 AND 90 THEN 'Highly Popular'
		WHEN Popularity > 90 THEN 'Trending'
END AS Popularity_rank
FROM master..spotify200$

ALTER TABLE master..spotify200$
ADD Popularity_rank VARCHAR(255)

UPDATE master..spotify200$
SET Popularity_rank =  CASE 
		WHEN Popularity BETWEEN 0 AND 20 THEN 'Unpopular'
		WHEN Popularity BETWEEN 21 AND 30 THEN 'Least popular'
		WHEN Popularity BETWEEN 31 AND 50 THEN 'Moderate'
		WHEN Popularity BETWEEN 51 AND 70 THEN 'Relatively popular'
		WHEN Popularity BETWEEN 71 AND 90 THEN 'Highly Popular'
		WHEN Popularity > 90 THEN 'Trending'
END 



--- Genre Percentage 
SELECT Genre1, 
COUNT(*) * 100.0/ SUM(COUNT(*)) OVER() AS Percentage
FROM master..spotify200$
GROUP BY Genre1
ORDER BY Percentage DESC




