-- Approved correspondence schema additions. No data changes or cascading deletes.
SET XACT_ABORT ON;
GO
IF COL_LENGTH('dbo.Correspondence_Threads', 'BroadcastID') IS NULL
    ALTER TABLE dbo.Correspondence_Threads ADD BroadcastID uniqueidentifier NULL;
IF COL_LENGTH('dbo.Correspondence_Threads', 'IsCompleted') IS NULL
    ALTER TABLE dbo.Correspondence_Threads ADD IsCompleted bit NULL;
GO
-- A broadcast ID is supplied once per send operation and reused for every recipient.
-- IsCompleted stays NULL until the creator closes the thread and records the outcome.
-- Existing CloseDate, Status, column names and nullability are preserved.

DECLARE @Relations TABLE (
    TableName sysname, ColumnName sysname, TargetTable sysname, ConstraintName sysname
);
INSERT @Relations VALUES
('Correspondence_Threads','SenderID','UsersMembers','FK_Correspondence_Threads_Sender'),
('Correspondence_Threads','ReceiverID','UsersMembers','FK_Correspondence_Threads_Receiver'),
('Correspondence_Threads','CreatedBy','UsersMembers','FK_Correspondence_Threads_CreatedBy'),
('Correspondence_Threads','ModifyUser','UsersMembers','FK_Correspondence_Threads_ModifyUser'),
('Correspondence_Thread_Messages','ThreadID','Correspondence_Threads','FK_Correspondence_Messages_Thread'),
('Correspondence_Thread_Messages','SenderID','UsersMembers','FK_Correspondence_Messages_Sender'),
('Correspondence_Thread_Messages','ReceivedID','UsersMembers','FK_Correspondence_Messages_Receiver'),
('Correspondence_Message_Attachments','MessageID','Correspondence_Thread_Messages','FK_Correspondence_Attachments_Message'),
('Correspondence_Notifications','UserID','UsersMembers','FK_Correspondence_Notifications_User'),
('Correspondence_Notifications','ThreadID','Correspondence_Threads','FK_Correspondence_Notifications_Thread'),
('Correspondence_Notifications','MessageID','Correspondence_Thread_Messages','FK_Correspondence_Notifications_Message');

DECLARE @Table sysname, @Column sysname, @Target sysname, @Constraint sysname, @SQL nvarchar(max);
DECLARE relations CURSOR LOCAL FAST_FORWARD FOR
    SELECT TableName, ColumnName, TargetTable, ConstraintName FROM @Relations;
OPEN relations;
FETCH NEXT FROM relations INTO @Table, @Column, @Target, @Constraint;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_key_columns f
        WHERE f.parent_object_id = OBJECT_ID('dbo.' + @Table)
          AND COL_NAME(f.parent_object_id, f.parent_column_id) = @Column
          AND f.referenced_object_id = OBJECT_ID('dbo.' + @Target)
          AND COL_NAME(f.referenced_object_id, f.referenced_column_id) = 'ID'
    )
    BEGIN
        SET @SQL = N'ALTER TABLE dbo.' + QUOTENAME(@Table) + N' WITH CHECK ADD CONSTRAINT '
            + QUOTENAME(@Constraint) + N' FOREIGN KEY (' + QUOTENAME(@Column)
            + N') REFERENCES dbo.' + QUOTENAME(@Target) + N'(ID);';
        EXEC sys.sp_executesql @SQL;
    END;
    FETCH NEXT FROM relations INTO @Table, @Column, @Target, @Constraint;
END;
CLOSE relations;
DEALLOCATE relations;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Threads') AND name='IX_Correspondence_Threads_BroadcastID')
    CREATE INDEX IX_Correspondence_Threads_BroadcastID ON dbo.Correspondence_Threads(BroadcastID) WHERE BroadcastID IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Threads') AND name='IX_Correspondence_Threads_Sender')
    CREATE INDEX IX_Correspondence_Threads_Sender ON dbo.Correspondence_Threads(SenderID,CreatedDate DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Threads') AND name='IX_Correspondence_Threads_Receiver')
    CREATE INDEX IX_Correspondence_Threads_Receiver ON dbo.Correspondence_Threads(ReceiverID,CreatedDate DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Thread_Messages') AND name='IX_Correspondence_Messages_Thread')
    CREATE INDEX IX_Correspondence_Messages_Thread ON dbo.Correspondence_Thread_Messages(ThreadID,ID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Message_Attachments') AND name='IX_Correspondence_Attachments_Message')
    CREATE INDEX IX_Correspondence_Attachments_Message ON dbo.Correspondence_Message_Attachments(MessageID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.Correspondence_Notifications') AND name='IX_Correspondence_Notifications_UserRead')
    CREATE INDEX IX_Correspondence_Notifications_UserRead ON dbo.Correspondence_Notifications(UserID,IsRead,SendDate DESC);
