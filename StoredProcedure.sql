CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear previous allocations (optional based on design)
    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;

    -- Cursor to loop through students sorted by GPA descending
    DECLARE student_cursor CURSOR FOR
        SELECT StudentId
        FROM StudentDetails
        ORDER BY GPA DESC;

    DECLARE @StudentId VARCHAR(20);
    DECLARE @SubjectId VARCHAR(20);
    DECLARE @Allocated BIT;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Allocated = 0;

        -- Loop through preferences 1 to 5
        DECLARE preference_cursor CURSOR FOR
            SELECT SP.SubjectId
            FROM StudentPreference SP
            JOIN SubjectDetails SD ON SP.SubjectId = SD.SubjectId
            WHERE SP.StudentId = @StudentId
            ORDER BY SP.Preference;

        OPEN preference_cursor;
        FETCH NEXT FROM preference_cursor INTO @SubjectId;

        WHILE @@FETCH_STATUS = 0 AND @Allocated = 0
        BEGIN
            -- Check remaining seats
            IF EXISTS (
                SELECT 1 FROM SubjectDetails
                WHERE SubjectId = @SubjectId AND RemainingSeats > 0
            )
            BEGIN
                -- Allocate subject
                INSERT INTO Allotments (SubjectId, StudentId)
                VALUES (@SubjectId, @StudentId);

                -- Decrease remaining seats
                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = @SubjectId;

                SET @Allocated = 1;
            END

            FETCH NEXT FROM preference_cursor INTO @SubjectId;
        END

        CLOSE preference_cursor;
        DEALLOCATE preference_cursor;

        -- If not allocated
        IF @Allocated = 0
        BEGIN
            INSERT INTO UnallotedStudents (StudentId)
            VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END;
