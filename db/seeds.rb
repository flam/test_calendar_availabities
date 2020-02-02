# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Create some already existing event for next weeks

Event.create(kind: :opening, starts_at: 1.day.from_now.round_off(30.minutes), ends_at: 2.days.from_now.round_off(30.minutes))
Event.create(kind: :opening, starts_at: 1.weeks.from_now.round_off(30.minutes), ends_at: (2.weeks.from_now + 3.day).round_off(30.minutes))
Event.create(kind: :opening, starts_at: 2.months.from_now.round_off(30.minutes), ends_at: (2.months.from_now + 1.day).round_off(30.minutes))
Event.create(kind: :opening, starts_at: 5.months.from_now.round_off(30.minutes), ends_at: (5.months.from_now + 1.day).round_off(30.minutes))

Event.create(kind: :appointment, starts_at: 1.day.from_now.round_off(30.minutes), ends_at: 2.days.from_now.round_off(30.minutes))
Event.create(kind: :appointment, starts_at: 1.week.from_now.round_off(30.minutes), ends_at: (2.weeks.from_now + 1.day).round_off(30.minutes))

# Don't use Event.appointment or Event.opening on create :
# Event.appointment.create(starts_at: 1.week.from_now, ends_at: 2.weeks.from_now + 1.day)
# Write a wrong query on method #available_opening 'kind' is calling twice (see log) : 
# Event.opening.between_dates(starts_at, ends_at) 
# => SELECT "events".* FROM "events" WHERE "events"."kind" = ? AND "events"."kind" = ? AND ((starts_at BETWEEN '2020-02-09 02:41:21.328920' AND '2020-02-17 02:41:21.329260') OR ('2020-02-09 02:41:21.328920' BETWEEN starts_at AND ends_at))  [["kind", 1], ["kind", 0]]