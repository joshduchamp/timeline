trigger TimelineEventMessageTrigger on Timeline_Event_Message__e (after insert) {
    TimelineEventMessageTriggerHandler.CreateTimelineEvents();
}