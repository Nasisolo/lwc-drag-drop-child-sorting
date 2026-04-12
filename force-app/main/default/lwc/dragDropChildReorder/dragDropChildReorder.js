import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getChildRelationships from '@salesforce/apex/DragDropChildReorderController.getChildRelationships';
import getChildRecords from '@salesforce/apex/DragDropChildReorderController.getChildRecords';
import saveReorder from '@salesforce/apex/DragDropChildReorderController.saveReorder';

const STEP = { RELATION: 'relation', REORDER: 'reorder' };

export default class DragDropChildReorder extends LightningElement {
    @api recordId;

    @track currentStep = STEP.RELATION;
    @track isLoading = false;
    @track errorMessage = '';

    @track relationships = [];
    @track selectedRelation = null;
    @track sortableRecords = [];

    _dragSrcIndex = null;
    _dragOverIndex = null;
    _loaded = false;

    // ─── CurrentPageReference fallback (Global QuickActions) ─────────────────

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (!pageRef) return;
        const stateId = pageRef.state && (pageRef.state.recordId || pageRef.state.inContextOfRef);
        if (stateId && !this.recordId) {
            try {
                const decoded = atob(stateId);
                const parsed = JSON.parse(decoded);
                this.recordId = (parsed.attributes && parsed.attributes.recordId) ? parsed.attributes.recordId : stateId;
            } catch (e) {
                this.recordId = stateId;
            }
        }
        if (this.recordId && !this._loaded) {
            this._loaded = true;
            this._loadRelationships();
        }
    }

    connectedCallback() {
        if (this.recordId && !this._loaded) {
            this._loaded = true;
            this._loadRelationships();
        }
    }

    disconnectedCallback() {
        // Reset all state so reopening the Quick Action always starts fresh.
        // Salesforce may reuse the component instance between modal opens
        // without fully destroying it, so _loaded must be cleared here.
        this._loaded = false;
        this.currentStep = STEP.RELATION;
        this.isLoading = false;
        this.errorMessage = '';
        this.relationships = [];
        this.selectedRelation = null;
        this.sortableRecords = [];
        this._dragSrcIndex = null;
        this._dragOverIndex = null;
    }

    // ─── Data Loading ─────────────────────────────────────────────────────────

    async _loadRelationships() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const result = await getChildRelationships({ recordId: this.recordId });
            if (!result || result.length === 0) {
                this.relationships = [];
                return;
            }
            if (result.length === 1) {
                // Auto-select and skip the list step
                this.selectedRelation = this._toRelation(result[0], true, 0);
                this.relationships = [this.selectedRelation];
                await this._loadChildRecords();
            } else {
                this.relationships = result.map((r, i) => this._toRelation(r, false, i));
                this.currentStep = STEP.RELATION;
            }
        } catch (e) {
            this.errorMessage = this._extractError(e);
        } finally {
            this.isLoading = false;
        }
    }

    async _loadChildRecords() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const result = await getChildRecords( { params : {
                parentId: this.recordId,
                childObjectApiName: this.selectedRelation.childObjectApiName,
                relationshipFieldName: this.selectedRelation.relationshipFieldName,
                sortFieldApiName: this.selectedRelation.sortFieldApiName,
                displayFieldApiName: this.selectedRelation.displayFieldApiName,
                displayFieldApiName2: this.selectedRelation.displayFieldApiName2 || null,
                sortDirection: this.selectedRelation.sortDirection || 'ASC',
                serializedConditions: this.selectedRelation.serializedConditions || null,
                conditionLogic: this.selectedRelation.conditionLogic || null
            } });
            this.sortableRecords = (result || []).map((r, i) => this._toSortableRecord(r, i + 1));
            this.currentStep = STEP.REORDER;
        } catch (e) {
            this.errorMessage = this._extractError(e);
        } finally {
            this.isLoading = false;
        }
    }

    // ─── UI Handlers ──────────────────────────────────────────────────────────

    handleRelationClick(event) {
        const relId = event.currentTarget.dataset.relId;
        this.relationships = this.relationships.map(r => ({
            ...r,
            isSelected: r.relId === relId,
            cssClass: this._relationCss(r.relId === relId)
        }));
        this.selectedRelation = this.relationships.find(r => r.relId === relId);
    }

    async handleNext() {
        if (!this.selectedRelation) return;
        await this._loadChildRecords();
    }

    handleBack() {
        this.errorMessage = '';
        this.sortableRecords = [];
        this.selectedRelation = null;
        this.relationships = this.relationships.map(r => ({ ...r, isSelected: false, cssClass: this._relationCss(false) }));
        this.currentStep = STEP.RELATION;
    }

    async handleSave() {
        if (!this.sortableRecords.length) return;
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const payload = this.sortableRecords.map((r, i) => ({ recordId: r.recordId, sortValue: i + 1 }));
            await saveReorder({
                childObjectApiName: this.selectedRelation.childObjectApiName,
                sortFieldApiName: this.selectedRelation.sortFieldApiName,
                serializedRecords: JSON.stringify(payload)
            });
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Records reordered successfully.', variant: 'success' }));
            getRecordNotifyChange([{ recordId: this.recordId }]);
            this.handleCancel();
        } catch (e) {
            this.errorMessage = this._extractError(e);
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ─── Drag & Drop Handlers ─────────────────────────────────────────────────

    handleDragStart(event) {
        const recordId = event.currentTarget.dataset.id;
        this._dragSrcIndex = this.sortableRecords.findIndex(r => r.recordId === recordId);
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this._dragSrcIndex);
        
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this._updateDragStyles();
        }, 0);
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDragEnter(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        
        // Se il mouse entra nello spazio vuoto (il contenitore list), dataset.id è undefined.
        if (!recordId) return;

        const overIndex = this.sortableRecords.findIndex(r => r.recordId === recordId);
        
        if (overIndex !== -1 && overIndex !== this._dragSrcIndex) {
            this._dragOverIndex = overIndex;
        }
        this._updateDragStyles();
    }

    handleDragLeave() { 
        /* Handled via dragEnter on other items */
    }

    handleDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const src = this._dragSrcIndex;
        const over = this._dragOverIndex;

        // Se abbiamo un'origine e una destinazione valide, scambiamo gli elementi nell'array
        if (src !== null && over !== null && src !== over) {
            const reordered = [...this.sortableRecords];
            const [moved] = reordered.splice(src, 1);
            reordered.splice(over, 0, moved);
            
            this.sortableRecords = reordered.map((r, i) => ({ ...r, newOrder: i + 1, cssClass: 'drag-row' }));
        } else if (src !== null) {
            this.sortableRecords = this.sortableRecords.map(r => ({ ...r, cssClass: 'drag-row' }));
        }
        
        this._dragSrcIndex = null;
        this._dragOverIndex = null;
    }

    handleDragEnd() {
        this._resetDragState();
    }

    _resetDragState() {
        this.sortableRecords = this.sortableRecords.map(r => ({ ...r, cssClass: 'drag-row' }));
        this._dragSrcIndex = null;
        this._dragOverIndex = null;
    }

    _updateDragStyles() {
        const src = this._dragSrcIndex;
        const over = this._dragOverIndex;

        this.sortableRecords = this.sortableRecords.map((r, i) => {
            let classes = ['drag-row'];
            
            if (i === src) {
                classes.push('drag-row--dragging');
            } else if (over !== null) {
                const isBetween = (i > src && i <= over) || (i < src && i >= over);
                if (isBetween) {
                    classes.push(src < over ? 'drag-row--shift-up' : 'drag-row--shift-down');
                }
            }
            
            return { ...r, cssClass: classes.join(' ') };
        });
    }

    // ─── Computed Properties ──────────────────────────────────────────────────

    get hasNoRelations() { return !this.isLoading && !this.errorMessage && this.relationships.length === 0; }
    get showRelationStep() { return !this.isLoading && !this.errorMessage && !this.hasNoRelations && this.currentStep === STEP.RELATION; }
    get showReorderStep() { return !this.isLoading && !this.errorMessage && this.currentStep === STEP.REORDER; }
    get hasNoRecords() { return this.sortableRecords.length === 0; }
    get isNextDisabled() { return !this.selectedRelation; }
    get reorderSubtitle() {
        if (!this.selectedRelation) return '';
        return `Sort field: ${this.selectedRelation.sortFieldApiName}  ·  Order: ${this.selectedRelation.sortDirection}`;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    _toRelation(r, selected, index = 0) {
        return {
            relId: String(index),
            childObjectApiName: r.childObjectApiName,
            childObjectLabel: r.childObjectLabel || r.childObjectApiName,
            relationshipLabel: r.relationshipLabel,
            relationshipFieldName: r.relationshipFieldName,
            sortFieldApiName: r.sortFieldApiName,
            displayFieldApiName: r.displayFieldApiName,
            displayFieldApiName2: r.displayFieldApiName2 || null,
            sortDirection: r.sortDirection || 'ASC',
            serializedConditions: r.serializedConditions || null,
            conditionLogic: r.conditionLogic || null,
            isSelected: selected,
            cssClass: this._relationCss(selected)
        };
    }

    _toSortableRecord(r, order) {
        return {
            recordId: r.recordId,
            name: r.name || r.recordId,
            secondaryName: r.secondaryName || null,
            sortValue: r.sortValue,
            newOrder: order,
            cssClass: 'drag-row'
        };
    }

    _relationCss(selected) { return selected ? 'relation-item relation-item--selected' : 'relation-item'; }
    _extractError(e) {
        if (e && e.body && e.body.message) return e.body.message;
        if (e && e.message) return e.message;
        return 'An unexpected error occurred.';
    }
}
