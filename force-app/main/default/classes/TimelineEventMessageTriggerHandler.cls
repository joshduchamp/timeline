public without sharing class TimelineEventMessageTriggerHandler 
{
    private static List<Timeline_Event_Message__e> messageList
    {
        get { return (List<Timeline_Event_Message__e>)Trigger.new; }
    }

    private static Map<String,Timeline_Event_Type_Field__mdt> fieldMap = Timeline_Event_Type_Field__mdt.getAll();

    public static void CreateTimelineEvents() 
    {
        List<Timeline_Event__c> timelineEventList = new List<Timeline_Event__c>();
        for(Timeline_Event_Message__e message : messageList) {
            Timeline_Event_Type__mdt eventTypeObj = Timeline_Event_Type__mdt.getInstance(message.Timeline_Event_Type__c);
            List<Timeline_Event_Type_Field__mdt> fieldList = getFields(eventTypeObj);

            Id objId = message.Event_Object_Id__c;
            Set<string> fieldSet = new Set<string>();
            fieldSet.add(eventTypeObj.Path_to_Parent_Id__c);
            for(Timeline_Event_Type_Field__mdt fieldObj : fieldList) {
                fieldSet.add(fieldObj.Api_Name__c);
            }
            string query = 
                'select ' + String.join(new List<string>(fieldSet), ', ')
                + ' from ' + eventTypeObj.Object_Api_Name__c
                + ' where Id = :objId';
            List<SObject> objList = Database.query(query);
            if (objList.isEmpty()) {
                continue;
            }
            SObject obj = objList[0];

            Timeline_Event__c timelineEventObj = new Timeline_Event__c(
                Timeline_Event_Type__c = message.Timeline_Event_Type__c,
                Parent_Id__c = (string)obj.get(eventTypeObj.Path_to_Parent_Id__c)
            );
            Map<String,Object> contentMap = new Map<String,List<Map<String,Object>>>();
            List<Object> contentFieldList = new List<Map<String,Object>>();
            contentMap.put('fields',contentFieldList);
            for(Timeline_Event_Type_Field__mdt fieldObj : fieldList) {
                Map<String,Object> contentFieldMap = new Map<String,Object>();
                contentFieldMap.put('Name', fieldObj.Label);
                contentFieldMap.put('Value', obj.get(fieldObj.Api_Name__c));
                contentFieldMap.put('Order', fieldObj.Order__c);
                contentFieldList.add(contentFieldMap);
            }
            timelineEventObj.Content__c = JSON.serialize(contentMap);
            timelineEventList.add(timelineEventObj);
        }
        insert timelineEventList;
    }

    private static List<Timeline_Event_Type_Field__mdt> getFields(Timeline_Event_Type__mdt eventTypeObj) {
        List<Timeline_Event_Type_Field__mdt> fieldList = new List<Timeline_Event_Type_Field__mdt>();
        for(Timeline_Event_Type_Field__mdt fieldObj : fieldMap.values()) {
            if (fieldObj.Timeline_Event_Type__c == eventTypeObj.Id) {
                fieldList.add(fieldObj);
            }
        }
        return fieldList;
    }
}
