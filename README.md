# LWC Drag & Drop Child Reorder

This generic Lightning Web Component (LWC) allows you to reorder child records of any Salesforce object through an intuitive drag-and-drop interface. It is highly configurable via Custom Metadata, eliminating the need for custom Apex code for each new relationship.

## Key Features
- **Drag-and-Drop:** Smooth interface for moving records and establishing a new order.
- **Multi-Relationship Support:** A single component can handle multiple types of child records for the same parent object.
- **Dynamic Configuration:** All settings (display fields, filters, sorting) are managed through metadata.
- **Apex Security:** Respects CRUD/FLS permissions and uses parameterized queries to prevent SOQL injection.
- **SLDS Design:** Seamlessly integrates with the Salesforce Lightning look and feel.

---

## Configuration via Custom Metadata

The core of the component is the `DragDropChildReorderConfig__mdt` Custom Metadata object. Each record defines how the component behaves for a specific parent-child relationship.

### Custom Metadata Fields

| Field | Description | Example |
| :--- | :--- | :--- |
| **Parent Object API Name** | The API name of the parent object where the Quick Action will be hosted. | `Account` |
| **Child Object API Name** | The API name of the child object to be reordered. | `Contact` |
| **Relationship Field API Name** | The Lookup or Master-Detail field on the child object pointing to the parent. | `AccountId` |
| **Relationship Label** | The label displayed in the component header for this relationship. | `Related Contacts` |
| **Sort Field API Name** | The field (usually Number type) used to store the sequence. | `SortOrder__c` |
| **Sort Direction** | The initial sort direction (`ASC` or `DESC`). | `ASC` |
| **Display Field API Name** | The primary field to identify the record in the list. | `Name` |
| **Display Field API Name 2** | (Optional) A secondary field displayed below the record title. | `Email` |
| **Child Query Condition (1-10)** | (Optional) Additional SOQL filters to limit the displayed records. | `Status__c = 'Active'` |
| **Condition Logic** | (Optional) Boolean logic for filters (e.g., `1 AND (2 OR 3)`). Defaults to `AND` for all. | `1 AND 2` |

---

## How to Use

### 1. Create a Configuration Record
1. Go to **Setup** -> **Custom Code** -> **Custom Metadata Types**.
2. Click **Manage Records** next to `Drag Drop Child Reorder Config`.
3. Create a new record filling in the fields described above.

### 2. Create a Quick Action
To make the component accessible, create a Quick Action on the parent object:
1. Go to **Object Manager** and select the parent object (e.g., `Account`).
2. Select **Buttons, Links, and Actions** -> **New Action**.
3. Configure the action:
    - **Action Type:** Lightning Web Component.
    - **Lightning Web Component:** `c:dragDropChildReorder`.
    - **Label:** "Reorder Children" (or your preferred name).
4. Save the Quick Action.

### 3. Add to Page Layout
1. In the parent object, go to **Page Layouts**.
2. Edit the desired layout.
3. Select **Mobile & Lightning Actions**.
4. Drag the new Quick Action into the **Salesforce Mobile and Lightning Experience Actions** section.
5. Save the layout.

---

## Technical Requirements
- The child object **must** have a Number field dedicated to storing the order (e.g., `SortOrder__c`).
- The component updates records in "User Mode" to ensure compliance with the current user's permissions.

---
---

# LWC Drag & Drop Child Reorder (Italiano)

Questo componente Lightning Web (LWC) generico consente di riordinare i record correlati (child) di qualsiasi oggetto Salesforce tramite un'interfaccia drag-and-drop intuitiva. È progettato per essere altamente configurabile tramite Custom Metadata, eliminando la necessità di scrivere codice Apex personalizzato per ogni nuova relazione.

## Funzionalità principali
- **Drag-and-Drop:** Interfaccia fluida per spostare i record e stabilire un nuovo ordine.
- **Supporto Multi-Relazione:** Un singolo componente può gestire più tipi di record correlati per lo stesso oggetto genitore.
- **Configurazione Dinamica:** Tutte le impostazioni (campi di visualizzazione, filtri, ordinamento) sono gestite tramite metadati.
- **Sicurezza Apex:** Rispetta le autorizzazioni CRUD/FLS e utilizza query parametrizzate per prevenire SOQL injection.
- **Design SLDS:** Si integra perfettamente con l'estetica di Salesforce Lightning.

---

## Configurazione tramite Custom Metadata

Il cuore del componente è l'oggetto Custom Metadata `DragDropChildReorderConfig__mdt`. Ogni record di questo metadato definisce come il componente deve comportarsi per una specifica relazione genitore-figlio.

### Campi del Custom Metadata

| Campo | Descrizione | Esempio |
| :--- | :--- | :--- |
| **Parent Object API Name** | L'API name dell'oggetto genitore su cui verrà attivata la Quick Action. | `Account` |
| **Child Object API Name** | L'API name dell'oggetto figlio che si desidera riordinare. | `Contact` |
| **Relationship Field API Name** | Il campo Lookup o Master-Detail sull'oggetto figlio che punta al genitore. | `AccountId` |
| **Relationship Label** | L'etichetta visualizzata nell'header del componente per questa relazione. | `Contatti Correlati` |
| **Sort Field API Name** | Il campo (solitamente di tipo Numero) utilizzato per memorizzare l'ordine. | `SortOrder__c` |
| **Sort Direction** | La direzione di ordinamento iniziale (`ASC` o `DESC`). | `ASC` |
| **Display Field API Name** | Il campo primario da mostrare per identificare il record nella lista. | `Name` |
| **Display Field API Name 2** | (Opzionale) Un secondo campo da mostrare sotto il titolo del record. | `Email` |
| **Child Query Condition (1-10)** | (Opzionale) Filtri SOQL aggiuntivi per limitare i record visualizzati. | `Status__c = 'Active'` |
| **Condition Logic** | (Opzionale) Logica booleana per i filtri (es. `1 AND (2 OR 3)`). Se vuoto, viene usato `AND` tra tutte le condizioni. | `1 AND 2` |

---

## Istruzioni per l'uso

### 1. Creazione del Record di Configurazione
1. Vai in **Setup** -> **Custom Code** -> **Custom Metadata Types**.
2. Clicca su **Manage Records** accanto a `Drag Drop Child Reorder Config`.
3. Crea un nuovo record compilando i campi descritti sopra.

### 2. Creazione della Quick Action
Per rendere il componente accessibile agli utenti, è necessario creare una Quick Action sull'oggetto genitore:
1. Vai su **Object Manager** e seleziona l'oggetto genitore (es. `Account`).
2. Seleziona **Buttons, Links, and Actions** -> **New Action**.
3. Configura l'azione:
    - **Action Type:** Lightning Web Component.
    - **Lightning Web Component:** `c:dragDropChildReorder`.
    - **Label:** "Riordina Figli" (o un nome a tua scelta).
4. Salva la Quick Action.

### 3. Aggiunta al Page Layout
1. Sempre nell'oggetto genitore, vai su **Page Layouts**.
2. Modifica il layout desiderato.
3. Seleziona **Mobile & Lightning Actions**.
4. Trascina la nuova Quick Action nella sezione **Salesforce Mobile and Lightning Experience Actions**.
5. Salva il layout.

---

## Requisiti Tecnici
- L'oggetto figlio **deve** avere un campo di tipo Numero dedicato alla memorizzazione dell'ordine (es. `SortOrder__c`).
- Il componente aggiorna i record in modalità "User Mode" per garantire il rispetto delle autorizzazioni dell'utente corrente.
