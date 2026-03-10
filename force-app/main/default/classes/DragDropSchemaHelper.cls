public without sharing class DragDropSchemaHelper {

	private static Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

	/**
	 * Auto-detects the Name field of the given object.
	 * Priority:
	 *  1. The field marked as isNameField()
	 *  2. The first STRING field found
	 *  3. Fallback: 'Id'
	 */
	public static String getNameField(String objectApiName) {
		String result;
		SObjectType objType = globalDescribeMap.get(objectApiName);

		if (objType != null) {
			Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

			for (Schema.SObjectField field : fieldMap.values()) {
				if (field.getDescribe().isNameField()) {
					result = field.getDescribe().getName();
				}
				if(String.isNotBlank(result)){
					break;
				}
			}
		}

		// Fallback to 'Id' if no Name field is found
		if (String.isBlank(result)) {
			result = 'Id';
		}
		return result;
	}

	/**
	 * Resolves a field value with dot-notation cross-object traversal support
	 * (e.g. 'Account.Name', 'Custom__r.Field__c').
	 */
	public static String resolveDisplayValue(SObject record, String fieldPath) {
		String result = '';
		if (String.isNotBlank(fieldPath)) {
			List<String> parts = fieldPath.split('\\.');
			if (parts.size() == 1) {
				Object val = record.get(fieldPath);
				result = val != null ? String.valueOf(val) : '';
			} else {
				SObject current = record;
				for (Integer i = 0; i < parts.size() - 1; i++) {
					if (current != null) {
						current = current.getSObject(parts[i]);
					}
				}
				if (current != null) {
					Object val = current.get(parts[parts.size() - 1]);
					result = val != null ? String.valueOf(val) : '';
				}
			}
		}
		return result;
	}

	/**
	 * Returns the label of the given SObject type, or the API name as fallback.
	 */
	public static String getObjectLabel(String objectApiName) {
		SObjectType objType = globalDescribeMap.get(objectApiName);
		return objType != null ? objType.getDescribe().getLabel() : objectApiName;
	}
}
