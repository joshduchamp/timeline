@IsTest
public class TimelineEventMessageTriggerHandlerTest 
{
    @IsTest
    static void OnInsert_CreatePlatformEventMessage() 
    {
        Contact contactObj = new Contact(
            FirstName = 'First',
            LastName = 'Last',
            MobilePhone = '1234567890'
        );
        insert contactObj;

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(new Timeline_Event_Message__e (
            Timeline_Event_Type__c = 'Contact_Updated',
            Event_Object_Id__c = contactObj.Id
        ));
        Test.stopTest();

        List<Timeline_Event__c> timelineEventList = [select Id from Timeline_Event__c];
        System.assertEquals(1, timelineEventList.size(), 'Timeline Event not created');
    }
}
