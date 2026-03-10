public without sharing class DragDropChildReorderService {

	/**
	 * Builds the list of ChildRelationInfo from CMDT records for the given parent object type.
	 *
	 * @param parentObjectApiName API name of the parent SObject (e.g. 'Account')
	 * @return List of populated ChildRelationInfo wrappers; empty if no CMDT records match
	 */
	public static List<DragDropChildReorderController.ChildRelationInfo> buildRelationInfoList(String parentObjectApiName){

		List<DragDropChildReorderController.ChildRelationInfo> results =
			new List<DragDropChildReorderController.ChildRelationInfo>();

		for (DragDropChildReorderConfig__mdt cfg : [
			SELECT RelationshipLabel__c, ChildObjectApiName__c, RelationshipFieldApiName__c, SortFieldApiName__c,
				DisplayFieldApiName__c, DisplayFieldApiName2__c, SortDirection__c, ConditionLogic__c,

				ChildQueryCondition1__c, ChildQueryCondition2__c, ChildQueryCondition3__c, ChildQueryCondition4__c,
				ChildQueryCondition5__c, ChildQueryCondition6__c, ChildQueryCondition7__c, ChildQueryCondition8__c,
				ChildQueryCondition9__c, ChildQueryCondition10__c

			FROM DragDropChildReorderConfig__mdt
			WHERE ParentObjectApiName__c = :parentObjectApiName
			ORDER BY RelationshipLabel__c ASC
		] ){
			DragDropChildReorderController.ChildRelationInfo info =
				new DragDropChildReorderController.ChildRelationInfo();

			info.childObjectApiName = cfg.ChildObjectApiName__c;
			info.childObjectLabel = DragDropSchemaHelper.getObjectLabel(cfg.ChildObjectApiName__c);
			info.relationshipLabel = cfg.RelationshipLabel__c;
			info.relationshipFieldName = cfg.RelationshipFieldApiName__c;
			info.sortFieldApiName = cfg.SortFieldApiName__c;
			info.displayFieldApiName = cfg.DisplayFieldApiName__c;
			info.displayFieldApiName2 = cfg.DisplayFieldApiName2__c;
			info.sortDirection = String.isBlank(cfg.SortDirection__c) ? 'ASC' : cfg.SortDirection__c.toUpperCase();
			info.conditionLogic = cfg.ConditionLogic__c;

			// Serialize conditions as a JSON array preserving index (null entries kept)
			info.serializedConditions  = JSON.serialize(new List<String>{
				cfg.ChildQueryCondition1__c, cfg.ChildQueryCondition2__c, cfg.ChildQueryCondition3__c,
				cfg.ChildQueryCondition4__c, cfg.ChildQueryCondition5__c, cfg.ChildQueryCondition6__c,
				cfg.ChildQueryCondition7__c, cfg.ChildQueryCondition8__c, cfg.ChildQueryCondition9__c,
				cfg.ChildQueryCondition10__c
			});
			results.add(info);
		}
		return results;
	}

	/**
	 * Executes the dynamic SOQL query and maps the result records into ChildRecordInfo wrappers.
	 *
	 * @param params	Query parameter wrapper (see DragDropChildReorderController.ChildRecordQueryParams)
	 * @return			List of populated ChildRecordInfo wrappers
	 */
	public static List<DragDropChildReorderController.ChildRecordInfo> fetchChildRecords(
		DragDropChildReorderController.ChildRecordQueryParams params
	){
		String displayField = String.isNotBlank(params.displayFieldApiName)
			? params.displayFieldApiName
			: DragDropSchemaHelper.getNameField(params.childObjectApiName);
		String display2Field = String.isNotBlank(params.displayFieldApiName2) ? params.displayFieldApiName2 : null;

		String query = DragDropQueryBuilder.buildQuery(
			params.childObjectApiName,
			params.relationshipFieldName,
			params.sortFieldApiName,
			displayField,
			display2Field,
			params.sortDirection,
			params.serializedConditions,
			params.conditionLogic
		);

		// parentId must be a local variable so the :parentId SOQL bind resolves correctly (query in line 88)
		Id parentId = params.parentId;

		List<DragDropChildReorderController.ChildRecordInfo> results =
			new List<DragDropChildReorderController.ChildRecordInfo>();

		for (SObject record : Database.query(query)) {
			DragDropChildReorderController.ChildRecordInfo info = new DragDropChildReorderController.ChildRecordInfo();
			info.recordId = record.Id;
			info.name = DragDropSchemaHelper.resolveDisplayValue(record, displayField);
			info.secondaryName = String.isNotBlank(display2Field)
				? DragDropSchemaHelper.resolveDisplayValue(record, display2Field) : null;
			Object rawSortVal = record.get(params.sortFieldApiName);
			info.sortValue = rawSortVal instanceof Decimal ? (Decimal)rawSortVal : null;
			results.add(info);
		}
		return results;
	}

	/**
	 * Updates the sort field on each child record with the new sequential values.
	 * @param childObjectApiName	API name of the child object
	 * @param sortFieldApiName		Field to update with the new sort value
	 * @param serializedRecords		JSON array of {recordId, sortValue} objects
	 */
	public static void performReorder(
		String childObjectApiName,
		String sortFieldApiName,
		String serializedRecords
	) {
		SObjectType objType = Schema.getGlobalDescribe().get(childObjectApiName);
		List<SObject> recordsToUpdate = new List<SObject>();
		for (Object raw : (List<Object>)JSON.deserializeUntyped(serializedRecords)) {
			Map<String, Object> objMap = (Map<String, Object>)raw;
			SObject rec = objType.newSObject((Id)objMap.get('recordId'));
			rec.put(sortFieldApiName, (Decimal)objMap.get('sortValue'));
			recordsToUpdate.add(rec);
		}
		if (!recordsToUpdate.isEmpty()) {
			update recordsToUpdate;
		}
	}
}
