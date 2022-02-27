trigger TimelineEventMessageTrigger on Timeline_Event_Message__e (after insert) {
    List<Timeline_Event_Message__e> messageList = (List<Timeline_Event_Message__e>)Trigger.new;
    TimelineEventMessageTriggerHandler.CreateTimelineEvents(messageList);
}