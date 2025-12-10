USE BridgewayDB;
GO

------------------------------------------------------------
-- Areeba - Search, Discovery, Ratings & Documentation Module
-- Responsibilities:
--   * Engineer profile views
--   * Search & filtering by skill/location/experience/vet_status/rating
--   * Ratings analytics (average rating, top engineers)
--   * Search-optimized indexes
--   * Documentation for Phase 2 PDF
------------------------------------------------------------


/************************************************************
  5. FUNCTIONS (Search & Ratings)
************************************************************/

------------------------------------------------------------
-- fn_AverageEngineerRating (MANDATORY)
------------------------------------------------------------
DROP FUNCTION IF EXISTS dbo.fn_AverageEngineerRating;
GO

CREATE FUNCTION dbo.fn_AverageEngineerRating
(
    @EngineerId INT
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Avg DECIMAL(5,2);

    SELECT @Avg = AVG(CAST(rating AS DECIMAL(5,2)))
    FROM dbo.tbl_Endorsement_Ratings
    WHERE engineer_id = @EngineerId;

    RETURN ISNULL(@Avg, 0.00);     -- return 0.00 if no ratings
END
GO


------------------------------------------------------------
-- fn_SplitSkillListToTable (OPTIONAL BUT IMPORTANT)
------------------------------------------------------------
CREATE FUNCTION dbo.fn_SplitSkillListToTable
(
    @SkillIdList NVARCHAR(MAX)
)
RETURNS @SkillIds TABLE (skill_id INT NOT NULL)
AS
BEGIN
    DECLARE @Pos INT = 0;
    DECLARE @Next INT;
    DECLARE @Value NVARCHAR(50);

    SET @SkillIdList = @SkillIdList + ',';   -- trailing comma ensures loop

    WHILE CHARINDEX(',', @SkillIdList, @Pos + 1) > 0
    BEGIN
        SET @Next = CHARINDEX(',', @SkillIdList, @Pos + 1);
        SET @Value = SUBSTRING(@SkillIdList, @Pos + 1, @Next - @Pos - 1);

        INSERT INTO @SkillIds SELECT CAST(@Value AS INT);

        SET @Pos = @Next;
    END

    RETURN;
END
GO



/************************************************************
  6. VIEWS (Talent Discovery & Profiles)
************************************************************/

------------------------------------------------------------
-- vw_EngineerFullProfile
------------------------------------------------------------
DROP VIEW IF EXISTS dbo.vw_EngineerFullProfile;
GO

CREATE VIEW dbo.vw_EngineerFullProfile AS
SELECT
    ep.engineer_id,
    u.full_name,
    u.email,
    ep.years_experience,
    ep.location,
    ep.availability,
    ep.vet_status,
    ep.portfolio_link,

    dbo.fn_AverageEngineerRating(ep.engineer_id) AS avg_rating,
    COUNT(er.rating) AS total_ratings,

    STRING_AGG(s.skill_name, ', ') AS skills_list
FROM dbo.tbl_Engineer_Profile ep
JOIN dbo.tbl_User u
    ON ep.engineer_id = u.user_id
LEFT JOIN dbo.tbl_Engineer_Skills es
    ON ep.engineer_id = es.engineer_id
LEFT JOIN dbo.tbl_Skill s
    ON es.skill_id = s.skill_id
LEFT JOIN dbo.tbl_Endorsement_Ratings er
    ON ep.engineer_id = er.engineer_id
GROUP BY
    ep.engineer_id,
    u.full_name,
    u.email,
    ep.years_experience,
    ep.location,
    ep.availability,
    ep.vet_status,
    ep.portfolio_link;
GO


------------------------------------------------------------
-- vw_EngineerSearchIndex (Flattened search-optimized view)
------------------------------------------------------------
DROP VIEW IF EXISTS dbo.vw_EngineerSearchIndex;
GO

CREATE VIEW dbo.vw_EngineerSearchIndex AS
SELECT
    engineer_id,
    full_name,
    email,
    years_experience,
    location,
    vet_status,
    avg_rating,
    skills_list,
    total_ratings
FROM dbo.vw_EngineerFullProfile;
GO



/************************************************************
  7. STORED PROCEDURES (Search & Analytics)
************************************************************/

------------------------------------------------------------
-- sp_SearchEngineersByFilters
------------------------------------------------------------
DROP PROCEDURE IF EXISTS dbo.sp_SearchEngineersByFilters;
GO

CREATE PROCEDURE dbo.sp_SearchEngineersByFilters
(
    @SkillIdList      NVARCHAR(MAX) = NULL,
    @MinExperience    INT           = NULL,
    @Location         NVARCHAR(100) = NULL,
    @MinRating        DECIMAL(5,2)  = NULL,
    @VetStatus        NVARCHAR(20)  = NULL,
    @Page             INT           = 1,
    @PageSize         INT           = 20
)
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- First CTE: Basic filters
    --------------------------------------------------------
    ;WITH Filtered AS
    (
        SELECT *
        FROM dbo.vw_EngineerSearchIndex
        WHERE (@VetStatus IS NULL OR vet_status = @VetStatus)
          AND (@MinExperience IS NULL OR years_experience >= @MinExperience)
          AND (@Location IS NULL OR location LIKE '%' + @Location + '%')
          AND (@MinRating IS NULL OR avg_rating >= @MinRating)
    ),

    --------------------------------------------------------
    -- Second CTE: Skill filtering
    --------------------------------------------------------
    SkillFiltered AS
    (
        SELECT f.*
        FROM Filtered f
        WHERE @SkillIdList IS NULL
           OR EXISTS (
                SELECT 1
                FROM dbo.fn_SplitSkillListToTable(@SkillIdList) s
                JOIN dbo.tbl_Engineer_Skills es
                    ON es.engineer_id = f.engineer_id
                   AND es.skill_id = s.skill_id
            )
    ),

    --------------------------------------------------------
    -- Third CTE: Pagination
    --------------------------------------------------------
    Paged AS
    (
        SELECT *,
               ROW_NUMBER() OVER (ORDER BY avg_rating DESC, years_experience DESC) AS rn
        FROM SkillFiltered
    )
    SELECT *
    FROM Paged
    WHERE rn BETWEEN (@Page - 1) * @PageSize + 1
               AND @Page * @PageSize;
END
GO



------------------------------------------------------------
-- sp_GetEngineerStats
------------------------------------------------------------
DROP PROCEDURE IF EXISTS dbo.sp_GetEngineerStats;
GO

CREATE PROCEDURE dbo.sp_GetEngineerStats
    @EngineerId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Applications summary
    SELECT 
        ep.engineer_id,
        COUNT(ja.job_id) AS total_applications,
        SUM(CASE WHEN ja.status = 'pending' THEN 1 ELSE 0 END) AS pending_applications,
        SUM(CASE WHEN ja.status = 'shortlisted' THEN 1 ELSE 0 END) AS shortlisted_applications,
        SUM(CASE WHEN ja.status = 'accepted' THEN 1 ELSE 0 END) AS accepted_applications,
        SUM(CASE WHEN ja.status = 'rejected' THEN 1 ELSE 0 END) AS rejected_applications,
        MIN(ja.created_at) AS first_application_date,
        MAX(ja.created_at) AS last_application_date,
        
        -- Ratings
        dbo.fn_AverageEngineerRating(@EngineerId) AS avg_rating,
        COUNT(er.rating) AS total_ratings,

        -- NEW: Match score
        AVG(ja.match_score) AS avg_match_score,

        -- NEW: Skills list
        STRING_AGG(s.skill_name, ', ') WITHIN GROUP (ORDER BY s.skill_name) AS skills_list,

        -- NEW: Profile fields
        ep.years_experience,
        ep.location,
        ep.vet_status

    FROM dbo.tbl_Engineer_Profile ep
    LEFT JOIN dbo.tbl_Job_Application ja
        ON ep.engineer_id = ja.engineer_id
    LEFT JOIN dbo.tbl_Endorsement_Ratings er
        ON ep.engineer_id = er.engineer_id
    LEFT JOIN dbo.tbl_Engineer_Skills es
        ON ep.engineer_id = es.engineer_id
    LEFT JOIN dbo.tbl_Skill s
        ON es.skill_id = s.skill_id
    WHERE ep.engineer_id = @EngineerId
    GROUP BY 
        ep.engineer_id,
        ep.years_experience,
        ep.location,
        ep.vet_status;
END;
GO




/************************************************************
  8. INDEX SUGGESTIONS (For Master Section 4)
************************************************************/

------------------------------------------------------------
-- Improve search performance (location + vet)
------------------------------------------------------------
CREATE INDEX IX_Engineer_Profile_Location_VetStatus
    ON dbo.tbl_Engineer_Profile (location, vet_status);
GO

------------------------------------------------------------
-- Improve rating-based lookups
------------------------------------------------------------
CREATE INDEX IX_Endorsement_Ratings_Engineer_RatingDate
    ON dbo.tbl_Endorsement_Ratings (engineer_id, [date]);
GO



/************************************************************
  END OF MODULE
************************************************************/