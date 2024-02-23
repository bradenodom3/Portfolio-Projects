-- FIFA PROJECT OVERVIEW

-- Contents:
	-- Retrieved all data
	-- Fixed contract column for easier analysis
		-- Added 'joined' column and 'YearsPro' column
	-- Removed units of measurement for easier numerical analysis
		-- Converted height to inches, weight to pounds, and all monetary columns to United States Dollars
	-- Broke position column into primary, secondary, and tertiary position columns
		-- Spelled out all positions to avoid confusion
	-- Corrected erroneous data types
	-- Cleaned name and club columns by replacing foreign characters (i.e. Ã§) with meaningful letters/symbols (i.e. ç)
	-- Divided LongName column into First and Last Name columns
	-- Ranked teams by average overall player rankings


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- GET ALL DATA (from Player table, Stats table, or from both)

SELECT *
FROM Portfolio..FIFA
ORDER BY PlayerID;

SELECT *
FROM Portfolio..FIFAStats
ORDER BY Overall DESC;

SELECT * 
FROM Portfolio..FIFA
JOIN Portfolio..FIFAStats
	ON Portfolio..FIFA.PlayerID = FIFAStats.PlayerID
ORDER BY Overall DESC;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- BREAKING CONTRACT COLUMN INTO START DATE, END DATE, AND LENGTH AND CORRECTING ITS DATA TYPE

		UPDATE Portfolio..FIFA
		SET Contract = NULL
		WHERE Contract = 'Free'

		ALTER TABLE Portfolio..FIFA
		ADD On_Loan NVARCHAR(255);

		UPDATE Portfolio..FIFA
		SET On_Loan = CASE WHEN Contract LIKE '%On Loan' THEN 'Yes'
			ELSE 'No'
			END

		ALTER TABLE Portfolio..FIFA
		ADD ContractStartYear int;

			UPDATE Portfolio..FIFA
			SET ContractStartYear = SUBSTRING(Contract, CHARINDEX(',', Contract) + 2, 4)
			WHERE Contract NOT LIKE '%~%';

			UPDATE Portfolio..FIFA
			SET ContractStartYear = SUBSTRING(Contract, CHARINDEX('~', Contract) - 6, 5)
			WHERE Contract LIKE '%~%';

		ALTER TABLE Portfolio..FIFA
		ADD ContractEndYear int;

			UPDATE Portfolio..FIFA
			SET ContractEndYear = '20' + SUBSTRING(LoanDateEnd, 8, 2)
			WHERE LoanDateEnd NOT LIKE '%~%';

			UPDATE Portfolio..FIFA
			SET ContractEndYear = SUBSTRING(Contract, CHARINDEX('~', Contract) +2 , 4)
			WHERE Contract LIKE '%~%';

		ALTER TABLE Portfolio..FIFA
		ADD ContractLength int;

			UPDATE Portfolio..FIFA
			SET ContractLength = ContractEndYear - ContractStartYear;

		ALTER TABLE Portfolio..FIFA
		ADD YearsPro INT;

			UPDATE Portfolio..FIFA
			SET YearsPro = DATEDIFF(Year, Joined, GETDATE())


---------------------------------------------------------------------------------------------

-- REMOVING UNITS OF MEASUREMENT AND FIXING DATA TYPES OF HEIGHT/WEIGHT FOR EASIER ANALYSIS
	-- Height

		UPDATE Portfolio..FIFA
		SET Height_cm = SUBSTRING(Height_cm, 1, 3)
		WHERE Height_cm LIKE '%cm%';

		UPDATE Portfolio..FIFA
		SET Height_cm = CONVERT(INT, LEFT(Height_cm, CHARINDEX('''', Height_cm) - 1)) * 12 + 
			CONVERT(INT, SUBSTRING(Height_cm, CHARINDEX('''', Height_cm) + 1, CHARINDEX('"', Height_cm) - CHARINDEX('''', Height_cm) - 1)) 
		WHERE Height_cm LIKE '%''%';


			ALTER TABLE Portfolio..FIFA
			ALTER COLUMN Height_cm float;


		UPDATE Portfolio..FIFA
		SET Height_cm = ROUND(Height_cm * 2.54, 0) 
		WHERE Height_cm < 100;

			ALTER TABLE Portfolio..FIFA
			ADD Height_Inches INT;

		-- 1 cm = 2.54 inches
		
		UPDATE Portfolio..FIFA
		SET Height_Inches = ROUND(Height_cm/2.54, 0);

	
	-- Weight

		UPDATE Portfolio..FIFA
		SET Weight_kg = REPLACE(Weight_kg, 'kg', '')
		WHERE Weight_kg LIKE '%kg%';

		UPDATE Portfolio..FIFA
		SET Weight_kg = REPLACE(Weight_kg, 'lbs', '')
		WHERE Weight_kg LIKE '%lb%';

		ALTER TABLE Portfolio..FIFA
		ALTER COLUMN Weight_kg float;
			
			UPDATE Portfolio..FIFA
			SET Weight_kg = Weight_kg * 0.453592
			WHERE Weight_kg >= 130;

		ALTER TABLE Portfolio..FIFA
		ADD Weight_lbs INT;


			-- 1 lb = 0.453592 kgs

			UPDATE Portfolio..FIFA
			SET Weight_lbs = ROUND(Weight_kg/0.453592, 0);


---------------------------------------------------------------------------------------------
	

--CONVERTING MONETARY COLUMNS TO US DOLLARS AND MAKING THEM NUMERICAL COLUMNS
	-- Value
		UPDATE Portfolio..FIFA
		SET Value_Euros = SUBSTRING(Value_Euros, 4, LEN(Value_Euros))

		
		UPDATE Portfolio..FIFA
		SET Value_Euros = CASE WHEN Value_Euros LIKE '%M%' THEN CAST(REPLACE(Value_Euros, 'M', '') AS DECIMAL(20, 2)) * 1000000
			WHEN Value_Euros LIKE '%K%' THEN CAST(REPLACE(Value_Euros, 'K', '') AS DECIMAL(20, 2)) * 1000
			ELSE CAST(Value_Euros AS DECIMAL(20, 2))
			END

		ALTER TABLE Portfolio..FIFA
		ALTER COLUMN Value_Euros DECIMAL(20,2);

		ALTER TABLE Portfolio..FIFA
		ADD Value_USDollars DECIMAL(20,2);
		
			-- 1 Euro = 1.08 US Dollars

			UPDATE Portfolio..FIFA
			SET Value_USDollars = Value_Euros * 1.08;

	
	-- Wage
		UPDATE Portfolio..FIFA
		SET AnnualWage_Euros = SUBSTRING(AnnualWage_Euros, 4, LEN(AnnualWage_Euros))


		UPDATE Portfolio..FIFA
		SET AnnualWage_Euros = CASE WHEN AnnualWage_Euros LIKE '%M%' THEN CAST(REPLACE(AnnualWage_Euros, 'M', '') AS DECIMAL(20, 2)) * 1000000
			WHEN AnnualWage_Euros LIKE '%K%' THEN CAST(REPLACE(AnnualWage_Euros, 'K', '') AS DECIMAL(20, 2)) * 1000
			ELSE CAST(AnnualWage_Euros AS DECIMAL(20, 2))
			END

		ALTER TABLE Portfolio..FIFA
		ALTER COLUMN AnnualWage_Euros DECIMAL(20,2);

		ALTER TABLE Portfolio..FIFA
		ADD AnnualWage_USDollars DECIMAL(20,2);

			UPDATE Portfolio..FIFA
			SET AnnualWage_USDollars = AnnualWage_Euros * 1.08;


	-- Release Clause
		UPDATE Portfolio..FIFA
		SET ReleaseClause_Euros = SUBSTRING(ReleaseClause_Euros, 4, LEN(ReleaseClause_Euros))


		UPDATE Portfolio..FIFA
		SET ReleaseClause_Euros = CASE WHEN ReleaseClause_Euros LIKE '%M%' THEN CAST(REPLACE(ReleaseClause_Euros, 'M', '') AS DECIMAL(20, 2)) * 1000000
			WHEN ReleaseClause_Euros LIKE '%K%' THEN CAST(REPLACE(ReleaseClause_Euros, 'K', '') AS DECIMAL(20, 2)) * 1000
			ELSE CAST(ReleaseClause_Euros AS DECIMAL(20, 2))
			END

		ALTER TABLE Portfolio..FIFA
		ALTER COLUMN ReleaseClause_Euros DECIMAL(20,2);

		ALTER TABLE Portfolio..FIFA
		ADD ReleaseClause_USDollars DECIMAL(20,2);

			UPDATE Portfolio..FIFA
			SET ReleaseClause_USDollars = AnnualWage_Euros * 1.08;

---------------------------------------------------------------------------------------------


-- BREAKING POSITIONS INTO PRIMARY/SECONDARY POSIITONS AND SPELLING THEM OUT FOR CLARITY
		SELECT Positions,
			CASE 
				WHEN CHARINDEX(',', Positions) > 0 
				THEN SUBSTRING(Positions, 1, CHARINDEX(',', Positions) - 1)
				ELSE Positions
				END AS PrimaryPosition,
			CASE	
				WHEN CHARINDEX(',', Positions) > 0
					AND CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) > 0
				THEN SUBSTRING(Positions, CHARINDEX(',', Positions) + 1, CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) - CHARINDEX(',', Positions) - 1)
				WHEN CHARINDEX(',', Positions) > 0 
				THEN SUBSTRING(Positions, CHARINDEX(',', Positions) + 1, LEN(Positions) - CHARINDEX(',', Positions)) 
				ELSE NULL
				END AS SecondaryPosition,
			CASE
				WHEN CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) > 0 
				THEN SUBSTRING(Positions, CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) + 1, LEN(Positions) - CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1))
				ELSE NULL
				END AS TertiaryPosition
		FROM Portfolio..FIFA;


		ALTER TABLE Portfolio..FIFA
		ADD PrimaryPosition nvarchar(255);

			UPDATE Portfolio..FIFA
			SET PrimaryPosition = CASE 
				WHEN CHARINDEX(',', Positions) > 0 
				THEN SUBSTRING(Positions, 1, CHARINDEX(',', Positions) - 1)
				ELSE Positions
				END;
		
		ALTER TABLE Portfolio..FIFA
		ADD SecondaryPosition nvarchar(255);

			UPDATE Portfolio..FIFA
			SET SecondaryPosition = CASE	
				WHEN CHARINDEX(',', Positions) > 0
					AND CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) > 0
				THEN SUBSTRING(Positions, CHARINDEX(',', Positions) + 1, CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) - CHARINDEX(',', Positions) - 1)
				WHEN CHARINDEX(',', Positions) > 0 
				THEN SUBSTRING(Positions, CHARINDEX(',', Positions) + 1, LEN(Positions) - CHARINDEX(',', Positions)) 
				ELSE NULL
				END;

		ALTER TABLE Portfolio..FIFA
		ADD TertiaryPosition nvarchar(255);

			UPDATE Portfolio..FIFA
			SET TertiaryPosition = 	CASE
				WHEN CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) > 0 
				THEN SUBSTRING(Positions, CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1) + 1, LEN(Positions) - CHARINDEX(',', Positions, CHARINDEX(',', Positions) + 1))
				ELSE NULL
				END;

	-- Spelling out positions for clarity's sake
	-- Query was copied for SecondaryPosition, TertiaryPosition, and BestPosition columns (not shown)

		UPDATE Portfolio..FIFA
		SET PrimaryPosition = 	CASE PrimaryPosition
			WHEN 'RW' THEN 'Right Wing'
			WHEN 'ST' THEN 'Striker'
			WHEN 'CF' THEN 'Center Forward'
			WHEN 'LW' THEN 'Left Wing'
			WHEN 'AM' THEN 'Attacking Midfielder'
			WHEN 'SW' THEN 'Sweeper'
			WHEN 'CB' THEN 'Center Back'
			WHEN 'CAM' THEN 'Central Attacking Midfielder'
			WHEN 'GK' THEN 'Goalkeeper'
			WHEN 'CDM' THEN 'Central Defensive Midfielder'
			WHEN 'CM' THEN 'Central Midfielder'
			WHEN 'LM' THEN 'Left Midfielder'
			WHEN 'RB' THEN 'Right Back'
			WHEN 'LB' THEN 'Left Back'
			WHEN 'RM' THEN 'Right Midfielder'
			WHEN 'RWB' THEN 'Right Wing Back'
			WHEN 'LWB' THEN 'Left Wing Back'
			ELSE NULL
			END;


---------------------------------------------------------------------------------------------


-- FIXING OTHER DATA TYPES
	-- JoinedTeam

		ALTER TABLE Portfolio..FIFA
		ALTER COLUMN Joined date;

	-- Loan Date End

		ALTER TABLE Portfolio..FIFA
		ALTER COLUMN LoanDateEnd date;

	
---------------------------------------------------------------------------------------------

-- CLEANING 'LONGNAME' COLUMN -- REMOVING WEIRD/FOREIGN CHARACTERS
	-- Performed same queries for 'Club' Column (not shown)

		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã©', 'é')
			WHERE LongName LIKE '%Ã©%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¡', 'á')
			WHERE LongName LIKE '%Ã¡%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ãº', 'ú')
			WHERE LongName LIKE '%Ãº%';	
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä‡', 'ć')
			WHERE LongName LIKE '%Ä‡%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã­', 'í')
			WHERE LongName LIKE '%Ã­%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã§', 'ç')
			WHERE LongName LIKE '%Ã§%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¶', 'ö')
			WHERE LongName LIKE '%Ã¶%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä±', 'ı')
			WHERE LongName LIKE '%Ä±%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã–', 'Ö')
			WHERE LongName LIKE '%Ã–%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¼', 'ü')
			WHERE LongName LIKE '%Ã¼%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã‡', 'Ç')
			WHERE LongName LIKE '%Ã‡%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã°', 'ð')
			WHERE LongName LIKE '%Ã°%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä', 'č')
			WHERE LongName LIKE '%Ä%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã³', 'ó')
			WHERE LongName LIKE '%Ã³%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã±', 'ñ')
			WHERE LongName LIKE '%Ã±%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Äƒ', 'ă')
			WHERE LongName LIKE '%Äƒ%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'ș', 's')
			WHERE LongName LIKE '%ș%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'ț', 't')
			WHERE LongName LIKE '%ț%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å‚', 'l')
			WHERE LongName LIKE '%Å‚%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¸', 'ø')
			WHERE LongName LIKE '%Ã¸%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¥', 'å')
			WHERE LongName LIKE '%Ã¥%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¦', 'æ')
			WHERE LongName LIKE '%Ã¦%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ãª', 'ê')
			WHERE LongName LIKE '%Ãª%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å¡', 'š')
			WHERE LongName LIKE '%Å¡%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'ÄŒ', 'Č')
			WHERE LongName LIKE '%ÄŒ%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã½', 'ý')
			WHERE LongName LIKE '%Ã½%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Åº', 'ź')
			WHERE LongName LIKE '%Åº%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã®', 'î')
			WHERE LongName LIKE '%Ã®%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'ÄŸ', 'ğ')
			WHERE LongName LIKE '%ÄŸ%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¨', 'è')
			WHERE LongName LIKE '%Ã¨%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å', 'L')
			WHERE LongName LIKE '%Å%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å„', 'ń')
			WHERE LongName LIKE '%Å„%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'È˜', 'Ş')
			WHERE LongName LIKE '%È˜%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã“', 'Ó')
			WHERE LongName LIKE '%Ã“%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¯', 'ï')
			WHERE LongName LIKE '%Ã¯%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä°', 'İ')
			WHERE LongName LIKE '%Ä°%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¤', 'ä')
			WHERE LongName LIKE '%Ã¤%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä…', 'ą')
			WHERE LongName LIKE '%Ä…%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä™', 'ę')
			WHERE LongName LIKE '%Ä™%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã‰', 'É')
			WHERE LongName LIKE '%Ã‰%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å ', 'Š')
			WHERE LongName LIKE '%Å %';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å¼', 'ż')
			WHERE LongName LIKE '%Å¼%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä›', 'ě')
			WHERE LongName LIKE '%Ä›%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã´', 'ô')
			WHERE LongName LIKE '%Ã´%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã¾', 'þ')
			WHERE LongName LIKE '%Ã¾%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä½', 'Ľ')
			WHERE LongName LIKE '%Ä½%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Åž', 'Ş')
			WHERE LongName LIKE '%Åž%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'ÅŸ', 'ş')
			WHERE LongName LIKE '%ÅŸ%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å¾', 'ž')
			WHERE LongName LIKE '%Å¾%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ä', 'ā')
			WHERE LongName LIKE '%Ä';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å½', 'Ž')
			WHERE LongName LIKE '%Å½%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Å›', 'ś')
			WHERE LongName LIKE '%Å›%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã‚', 'Â')
			WHERE LongName LIKE '%Ã‚%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã˜', 'Ø')
			WHERE LongName LIKE '%Ã˜%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã€', 'A')
			WHERE LongName LIKE '%Ã€%';
		UPDATE Portfolio..FIFA
			SET LongName = REPLACE(LongName, 'Ã€', 'A')
			WHERE LongName LIKE '%Ã€%';


---------------------------------------------------------------------------------------------


-- SEPARATE 'LONGNAME' INTO FIRST/LAST

		ALTER TABLE Portfolio..FIFA
		ADD FirstName nvarchar(255);

			UPDATE Portfolio..FIFA
			SET FirstName = LEFT(LongName, CHARINDEX(' ', LongName) - 1);

		ALTER TABLE Portfolio..FIFA
		ADD LastName nvarchar(255);

			UPDATE Portfolio..FIFA
			SET LastName = SUBSTRING(LongName, CHARINDEX(' ', LongName) + 1, LEN(LongName));

	
---------------------------------------------------------------------------------------------


-- RANKING TEAMS BY AVERAGE OVERALL PLAYER RATING
	
	CREATE VIEW ClubRankView AS 
	WITH ClubRanks AS 
		(
		SELECT Club, AVG(Overall) AS AvgOverall
		FROM Portfolio..FIFA AS f
		JOIN Portfolio..FIFAStats AS s
		ON f.PlayerID = s.PlayerID
		GROUP BY Club
		)
	SELECT Club, AvgOverall, RANK() OVER (ORDER BY AvgOverall DESC) AS ClubRank
	FROM ClubRanks;

	SELECT *
	FROM Portfolio..ClubRankView;

