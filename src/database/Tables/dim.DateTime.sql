CREATE TABLE [dim].[DateTime]
(
[DateTimeID] [bigint] NOT NULL,
[DateID] [bigint] NULL,
[YearID] [bigint] NULL,
[MonthYearID] [bigint] NULL,
[MonthID] [bigint] NULL,
[WeekYearID] [bigint] NULL,
[WeekID] [bigint] NULL,
[DayMonthID] [bigint] NULL,
[DayID] [bigint] NULL,
[DayOfWeekID] [bigint] NULL,
[HourDateID] [bigint] NULL,
[HourID] [bigint] NULL,
[MinuteHourDateID] [bigint] NULL,
[MinuteID] [bigint] NULL,
[MonthYearAsText] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MonthAsText] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WeekYearAsText] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WeekAsText] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayMonthYearAsText] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayMonthAsText] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayAsText] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayOfWeekAsText] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HourDateAsText] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HourAsText] [varchar] (6) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MinuteHourDateAsText] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MinuteHourAsText] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StartOfDayAsDate] [datetime] NULL,
[DateAndTimeAsDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dim].[DateTime] ADD CONSTRAINT [PK_DateTime] PRIMARY KEY CLUSTERED  ([DateTimeID]) ON [PRIMARY]
GO
