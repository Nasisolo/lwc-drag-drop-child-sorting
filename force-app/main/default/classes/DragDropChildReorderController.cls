public without sharing class DragDropChildReorderController {

    public class ChildRelationInfo {
        @AuraEnabled public String childObjectApiName    { get; set; }
        @AuraEnabled public String childObjectLabel      { get; set; }
        @AuraEnabled public String relationshipLabel     { get; set; }
        @AuraEnabled public String relationshipFieldName { get; set; }
        @AuraEnabled public String sortFieldApiName      { get; set; }
        @AuraEnabled public String displayFieldApiName   { get; set; }
        @AuraEnabled public String displayFieldApiName2  { get; set; }
        @AuraEnabled public String sortDirection         { get; set; }

        // Serialized JSON array of 10 conditions (index 0-9 → condition 1-10)
        @AuraEnabled public String serializedConditions  { get; set; }
        @AuraEnabled public String conditionLogic        { get; set; }
    }

    public class ChildRecordInfo {
        @AuraEnabled public String  recordId      { get; set; }
        @AuraEnabled public String  name          { get; set; }
        @AuraEnabled public String  secondaryName { get; set; }
        @AuraEnabled public Decimal sortValue     { get; set; }
    }

    /**
     * Parameter wrapper for getChildRecords – avoids an ExcessiveParameterList violation.
     * The LWC passes this as a single object; Apex deserialises it automatically.
     */
    public class ChildRecordQueryParams {
        @AuraEnabled public String parentId               { get; set; }
        @AuraEnabled public String childObjectApiName     { get; set; }
        @AuraEnabled public String relationshipFieldName  { get; set; }
        @AuraEnabled public String sortFieldApiName       { get; set; }
        @AuraEnabled public String displayFieldApiName    { get; set; }
        @AuraEnabled public String displayFieldApiName2   { get; set; }
        @AuraEnabled public String sortDirection          { get; set; }
        @AuraEnabled public String serializedConditions   { get; set; }
        @AuraEnabled public String conditionLogic         { get; set; }
    }

    /**
     * Returns the list of CMDT-configured relationships for the current record's object type.
     */
    @AuraEnabled(cacheable=True)
    public static List<ChildRelationInfo> getChildRelationships(String recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException(
                'recordId is missing. Make sure the Quick Action is placed on a record page.'
            );
        }
        String parentObjectApiName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        return DragDropChildReorderService.buildRelationInfoList(parentObjectApiName);
    }

    /**
     * Dynamically queries child records using CMDT configuration.
     */
    @AuraEnabled
    public static List<ChildRecordInfo> getChildRecords(ChildRecordQueryParams params) {
        return DragDropChildReorderService.fetchChildRecords(params);
    }

    /**
     * Updates the sort field on each child record with new sequential values.
     */
    @AuraEnabled
    public static void saveReorder(String childObjectApiName, String sortFieldApiName, String serializedRecords) {
        try {
            DragDropChildReorderService.performReorder(childObjectApiName, sortFieldApiName, serializedRecords);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}