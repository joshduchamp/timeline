public without sharing class TimelineEventMessageTriggerHandler 
{
    public static void CreateTimelineEvents(List<Timeline_Event_Message__e> messageList) 
    {
        Map<String,List<Timeline_Event_Message__e>> messagesByEventType = getMessagesByEventType(messageList);

        List<Timeline_Event__c> timelineEventList = new List<Timeline_Event__c>();
        for(String eventTypeStr : messagesByEventType.keySet()) 
        {
            Timeline_Event_Type__mdt eventTypeObj = Timeline_Event_Type__mdt.getInstance(eventTypeStr);
            List<Timeline_Event_Type_Field__mdt> fieldList = getFields(eventTypeObj);

            Map<String,SObject> objMap = getObjectsByEventType(eventTypeStr, messagesByEventType);

            for(Timeline_Event_Message__e message : messagesByEventType.get(eventTypeStr)) 
            {
                SObject obj = objMap.get(message.Event_Object_Id__c);
                if (obj == null) continue;

                timelineEventList.add(createTimelineEventObj(message, obj));
            }
        }
        insert timelineEventList;
    }

    private static Map<String,List<Timeline_Event_Message__e>> getMessagesByEventType(List<Timeline_Event_Message__e> messageList) {
        Map<String,List<Timeline_Event_Message__e>> messagesByEventType = new Map<String,List<Timeline_Event_Message__e>>();
        for(Timeline_Event_Message__e message : messageList) {
            if (!messagesByEventType.containsKey(message.Timeline_Event_Type__c)) {
                messagesByEventType.put(message.Timeline_Event_Type__c, new List<Timeline_Event_Message__e>());
            }
            messagesByEventType.get(message.Timeline_Event_Type__c).add(message);
        }
        return messagesByEventType;
    }

    private static List<Timeline_Event_Type_Field__mdt> getFields(Timeline_Event_Type__mdt eventTypeObj) 
    {
        List<Timeline_Event_Type_Field__mdt> fieldList = new List<Timeline_Event_Type_Field__mdt>();
        for(Timeline_Event_Type_Field__mdt fieldObj : Timeline_Event_Type_Field__mdt.getAll().values()) {
            if (fieldObj.Timeline_Event_Type__c == eventTypeObj.Id) {
                fieldList.add(fieldObj);
            }
        }
        return fieldList;
    }

    private static Map<String,SObject> getObjectsByEventType(String eventTypeStr, Map<String,List<Timeline_Event_Message__e>> messagesByEventType)
    {
        Set<Id> idSet = new Set<Id>();
        for (Timeline_Event_Message__e message : messagesByEventType.get(eventTypeStr)) {
            idSet.add(message.Event_Object_Id__c);
        }

        Timeline_Event_Type__mdt eventTypeObj = Timeline_Event_Type__mdt.getInstance(eventTypeStr);
        Set<string> fieldSet = new Set<string>();
        fieldSet.add(eventTypeObj.Path_to_Parent_Id__c);
        for(Timeline_Event_Type_Field__mdt fieldObj : getFields(eventTypeObj)) {
            fieldSet.add(fieldObj.Api_Name__c);
        }
        string query = 
            'select ' + String.join(new List<string>(fieldSet), ', ')
            + ' from ' + eventTypeObj.Object_Api_Name__c
            + ' where Id = :idSet';
        Map<String,SObject> objMap = new Map<String,SObject>(Database.query(query));
        return objMap;
    }

    private static Timeline_Event__c createTimelineEventObj(Timeline_Event_Message__e message, SObject obj) 
    {
        Timeline_Event_Type__mdt eventTypeObj = Timeline_Event_Type__mdt.getInstance(message.Timeline_Event_Type__c);
        Timeline_Event__c timelineEventObj = new Timeline_Event__c(
            Timeline_Event_Type__c = message.Timeline_Event_Type__c,
            Parent_Id__c = (string)obj.get(eventTypeObj.Path_to_Parent_Id__c)
        );

        TimelineEventContent content = new TimelineEventContent();
        for(Timeline_Event_Type_Field__mdt fieldObj : getFields(eventTypeObj)) {
            TimelineEventContentField contentField = new TimelineEventContentField();
            contentField.Name = fieldObj.Label;
            contentField.Value = obj.get(fieldObj.Api_Name__c);
            contentField.Order = Integer.valueOf(fieldObj.Order__c);
            content.fields.add(contentField);
        }
        timelineEventObj.Content__c = JSON.serialize(content);

        return timelineEventObj;
    }

    private class TimelineEventContent
    {
        public List<TimelineEventContentField> fields = new List<TimelineEventContentField>();
    }

    private class TimelineEventContentField
    {
        public String Name;
        public Object Value;
        public Integer Order;
    }
}
