public without sharing class DragDropQueryBuilder {

	/**
	 * Builds and returns the full SOQL query string for fetching child records
	 * by composing the SELECT/FROM, WHERE, and ORDER BY clauses.
	 *
	 * @param childObjectApiName		API name of the child object
	 * @param relationshipFieldName		Lookup/master field pointing to the parent (e.g. 'AccountId')
	 * @param sortFieldApiName			Field used for ORDER BY
	 * @param displayField				Primary display field (already resolved, never blank)
	 * @param display2Field				Secondary display field, or null
	 * @param sortDirection				'ASC' or 'DESC'
	 * @param serializedConditions		JSON array of up to 10 CMDT condition strings
	 * @param conditionLogic			Custom logic expression (e.g. '1 AND (2 OR 3)'), or blank for AND-all
	 * @return							SOQL string with a `:parentId` bind variable
	 */
	@SuppressWarnings('PMD.ExcessiveParameterList')
	public static String buildQuery(
		String childObjectApiName,
		String relationshipFieldName,
		String sortFieldApiName,
		String displayField,
		String display2Field,
		String sortDirection,
		String serializedConditions,
		String conditionLogic
	){
		return buildSelectFrom(childObjectApiName, sortFieldApiName, displayField, display2Field)
			+ buildWhere(relationshipFieldName, serializedConditions, conditionLogic)
			+ buildOrderBy(sortFieldApiName, sortDirection);
	}

	/**
	 * Builds the SELECT … FROM … clause.
	 *
	 * @param childObjectApiName	Object to select from
	 * @param sortFieldApiName		Included in SELECT when it differs from displayField
	 * @param displayField			Primary display field (never blank)
	 * @param display2Field			Secondary display field, or null
	 * @return						' SELECT Id, … FROM ObjectApiName'
	 */
	private static String buildSelectFrom(
		String childObjectApiName,
		String sortFieldApiName,
		String displayField,
		String display2Field
	){
		Set<String> selectFields = new Set<String>{'Id', displayField};
		if (String.isNotBlank(sortFieldApiName) && sortFieldApiName != displayField) {
			selectFields.add(sortFieldApiName);
		}
		if (String.isNotBlank(display2Field)){
			selectFields.add(display2Field);
		}
		return ' SELECT ' + String.join(new List<String>(selectFields), ', ')
			+ ' FROM ' + childObjectApiName;
	}

	/**
	 * Builds the WHERE clause, including the parent-id filter and any extra CMDT conditions.
	 *
	 * @param relationshipFieldName		Field that stores the parent Id (bind variable :parentId)
	 * @param serializedConditions		JSON array of up to 10 CMDT condition strings
	 * @param conditionLogic			Custom logic expression, or blank for AND-all
	 * @return							' WHERE relField = :parentId[ AND (extraConditions)]'
	 */
	private static String buildWhere(
		String relationshipFieldName,
		String serializedConditions,
		String conditionLogic
	){
		String whereClause = ' WHERE ' + relationshipFieldName + ' = :parentId';
		String extraConditions = buildConditionClause(serializedConditions, conditionLogic);
		if (String.isNotBlank(extraConditions)) {
			whereClause += ' AND (' + extraConditions + ')';
		}
		return whereClause;
	}

	/**
	 * Builds the ORDER BY clause.
	 *
	 * @param sortFieldApiName		Field to sort by
	 * @param sortDirection			'ASC' or 'DESC' (anything else defaults to ASC)
	 * @return						' ORDER BY sortField ASC|DESC NULLS LAST'
	 */
	private static String buildOrderBy(String sortFieldApiName, String sortDirection) {
		String direction = (sortDirection == 'DESC') ? 'DESC' : 'ASC';
		return ' ORDER BY ' + sortFieldApiName + ' ' + direction + ' NULLS LAST';
	}

	/**
	 * Builds the extra WHERE condition string from the 10 CMDT conditions and the logic expression.
	 *
	 * Logic resolution:
	 *	- If conditionLogic is blank → AND all non-blank conditions.
	 *	- If conditionLogic is set → replace each number N (1-10) with the corresponding
	 *		condition wrapped in parentheses. Numbers are replaced from highest to lowest
	 *		to avoid partial matches (e.g. 10 before 1).
	 */
	private static String buildConditionClause(String serializedConditions, String conditionLogic) {
		String result = null;
		Map<Integer, String> condMap = parseConditionMap(serializedConditions);
		if (condMap != null && !condMap.isEmpty()) {
			if (String.isBlank(conditionLogic)) {
				result = applyDefaultLogic(condMap);
			} else {
				result = conditionLogic;
				for (Integer i = 10; i >= 1; i--) {
					if (condMap.containsKey(i)) {
						result = result.replaceAll('(?<![0-9])' + i + '(?![0-9])', '(' + condMap.get(i) + ')');
					}
				}
			}
		}
		return result;
	}

	/**
	 * Parses the serialized JSON conditions into a 1-based index map of non-blank condition strings.
	 * Returns null if the input is blank or unparseable.
	 */
	private static Map<Integer, String> parseConditionMap(String serializedConditions) {
		Map<Integer, String> result = null;
		if (String.isNotBlank(serializedConditions)) {
			List<Object> raw;
			try {
				raw = (List<Object>)JSON.deserializeUntyped(serializedConditions);
			} catch (Exception e) {
				raw = null;
			}
			if (raw != null) {
				result = new Map<Integer, String>();
				for (Integer i = 0; i < raw.size(); i++) {
					String val = raw[i] != null ? String.valueOf(raw[i]).trim() : null;
					if (String.isNotBlank(val)) {
						result.put(i + 1, val);
					}
				}
			}
		}
		return result;
	}

	/**
	 * Joins all condition values with AND (used when no custom conditionLogic is set).
	 */
	private static String applyDefaultLogic(Map<Integer, String> condMap) {
		return String.join(new List<String>(condMap.values()), ' AND ');
	}
}
