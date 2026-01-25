# State-Space Object System Implementation Plan

## Overview
This plan implements a comprehensive state-space object system that ties no-code states to object models, enables state-definition templates, and properly overlays Angular components on D3-rendered state circles.

## Phase 1: Backend Foundation (Model Layer)

### 1.1 Extend polyTypedObject with State-Space Configuration
**Files:** `polari-rf-node/polari-framework/polariDataTyping/polyTyping.py`

The `isStateSpaceObject` flag already exists (line 131). We need to add:
- `stateSpaceEventMethods: list` - Methods marked as state-space events
- `stateSpaceDisplayFields: list` - Fields to display in the state UI (1-2 per row)
- `stateSpaceFieldLayout: dict` - Configuration for field visibility/layout

```python
# Add to polyTypedObject.__init__:
self.stateSpaceEventMethods = []  # Methods decorated with @stateSpaceEvent
self.stateSpaceDisplayFields = []  # Which fields show in state UI
self.stateSpaceFieldLayout = {}   # {fieldName: {row: 1, visible: True}}
```

### 1.2 Create @stateSpaceEvent Decorator
**New File:** `polari-rf-node/polari-framework/polariDataTyping/stateSpaceDecorators.py`

```python
def stateSpaceEvent(func):
    """Marks a method as a state-space event that can generate slots."""
    func._is_state_space_event = True
    func._input_params = inspect.signature(func).parameters
    func._output_type = func.__annotations__.get('return', None)
    @wraps(func)
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper
```

### 1.3 Create StateDefinition Model
**New File:** `polari-rf-node/polari-framework/polariDataTyping/stateDefinition.py`

A StateDefinition ties a polyTypedObject to specific state-space configuration:
- Links to source polyTypedObject
- Defines which event method to use
- Specifies input/output slot generation rules
- Configures field display options

---

## Phase 2: Backend API Endpoints

### 2.1 Add State-Space Toggle to /createClass
**File:** `polari-rf-node/polari-framework/polariApiServer/polariServerBaseRoutes.py`

Extend the createClass endpoint to accept:
```python
{
    "className": "...",
    "isStateSpaceObject": true,
    "stateSpaceDisplayFields": ["field1", "field2"],
    "stateSpaceFieldLayout": {...}
}
```

### 2.2 Create State Definition CRUD Endpoints
**File:** `polari-rf-node/polari-framework/polariApiServer/polariServerBaseRoutes.py`

- `POST /stateDefinition` - Create a new state definition
- `GET /stateDefinitions` - List all state definitions
- `GET /stateDefinitions/{className}` - Get definitions for a class
- `PUT /stateDefinition/{id}` - Update a state definition
- `DELETE /stateDefinition/{id}` - Delete a state definition

### 2.3 Endpoint to Retrieve State-Space Classes
- `GET /stateSpaceClasses` - Returns all classes where `isStateSpaceObject=True`

---

## Phase 3: Frontend Models

### 3.1 Create StateDefinition Model
**New File:** `polari-platform-angular/src/app/models/noCode/StateDefinition.ts`

```typescript
export interface StateDefinition {
    id: string;
    name: string;
    sourceClassName: string;        // The polyTypedObject class name
    eventMethodName: string;        // Which @stateSpaceEvent to use
    inputSlots: SlotDefinition[];   // Generated from event params
    outputSlots: SlotDefinition[];  // Generated from event return
    displayFields: FieldDisplay[];  // Fields to show in state UI
    fieldLayout: 'single' | 'double'; // 1 or 2 fields per row
}

export interface SlotDefinition {
    paramName: string;
    paramType: string;
    isInput: boolean;
    isOutput: boolean;
}

export interface FieldDisplay {
    fieldName: string;
    visible: boolean;
    row: number;
}
```

### 3.2 Extend NoCodeState Model
**File:** `polari-platform-angular/src/app/models/noCode/NoCodeState.ts`

Add:
```typescript
stateDefinitionId?: string;      // Links to StateDefinition
objectInstanceId?: string;       // Links to actual object instance
boundObjectClass?: string;       // Class name of bound object
```

---

## Phase 4: Frontend Services

### 4.1 StateDefinition Service
**New File:** `polari-platform-angular/src/app/services/no-code-services/state-definition.service.ts`

- CRUD operations for StateDefinitions
- Cache and manage available definitions
- Map class events to slot configurations

### 4.2 Extend NoCodeSolutionStateService
**File:** `polari-platform-angular/src/app/services/no-code-services/no-code-solution-state.service.ts`

Add methods to:
- Associate states with object instances
- Retrieve bound object data for display

---

## Phase 5: Class Creation UI Enhancement

### 5.1 Add State-Space Toggle to CreateNewClassComponent
**Files:**
- `polari-platform-angular/src/app/components/create-new-class/create-new-class.ts`
- `polari-platform-angular/src/app/components/create-new-class/create-new-class.html`

Add checkbox/toggle:
```typescript
isStateSpaceObject = false;
isStateSpaceControl = new FormControl(false);
```

HTML:
```html
<mat-checkbox formControlName="isStateSpace">
    Enable as State-Space Object
</mat-checkbox>
```

### 5.2 Create VariableModifier Extension for State Display
Allow marking which variables should display in state UI and their layout.

---

## Phase 6: State Creation Interface (New Component)

### 6.1 StateDefinitionCreator Component
**New Files:**
- `polari-platform-angular/src/app/components/state-definition-creator/state-definition-creator.ts`
- `polari-platform-angular/src/app/components/state-definition-creator/state-definition-creator.html`
- `polari-platform-angular/src/app/components/state-definition-creator/state-definition-creator.css`

Features:
- Select from available state-space-enabled classes
- Choose which @stateSpaceEvent method to use
- Configure input/output slots (auto-generated from event signature)
- Select which fields to display (1-2 per row toggle)
- Preview the resulting state template

---

## Phase 7: D3 Overlay Integration (Critical Path)

### 7.1 Calculate Overlay Position from D3 Group Transform
**Key Insight:** The inner square is already defined in CircleStateLayer (lines 479-486):
```typescript
group.append('rect')
    .classed('overlay-component', true)
    .attr('x', -(1.4 * datapoint.radius) / 2)
    .attr('y', -(1.4 * datapoint.radius) / 2)
    .attr('width', 1.4 * datapoint.radius)
    .attr('height', 1.4 * datapoint.radius)
```

The overlay needs to match this rect's screen position after zoom/pan transforms.

### 7.2 Create StateOverlayManager Service
**New File:** `polari-platform-angular/src/app/services/no-code-services/state-overlay-manager.service.ts`

Responsibilities:
- Track which states have overlaid components
- Calculate screen coordinates from D3 transform matrix
- Create/destroy overlay components on state selection
- Update overlay positions during zoom/pan

### 7.3 Modify CircleStateLayer to Emit Overlay Events
**File:** `polari-platform-angular/src/app/models/noCode/d3-extensions/CircleStateLayer.ts`

Add:
- Method to get overlay rect bounds in screen coordinates
- Event emission when state is clicked for editing
- Integration point for overlay component injection

### 7.4 Create Dynamic State Overlay Component
**New File:** `polari-platform-angular/src/app/components/custom-no-code/state-overlay/state-overlay.ts`

Features:
- Dynamic field display based on StateDefinition
- 1 or 2 fields per row layout
- Shows bound object data
- Scales with zoom (or fixed size with repositioning)

### 7.5 Update CustomNoCodeComponent
**File:** `polari-platform-angular/src/app/components/custom-no-code/custom-no-code.ts`

- Listen for state click events
- Use StateOverlayManager to create overlays
- Handle overlay lifecycle during drag/zoom

---

## Phase 8: Testing & Integration

### 8.1 Create Test State-Space Class
- Create a sample class with @stateSpaceEvent decorator
- Create a StateDefinition for it
- Test in no-code editor

### 8.2 Verify Overlay Positioning
- Test overlay matches inner rect during:
  - Initial render
  - Pan/zoom
  - State drag
  - Window resize

---

## Implementation Order (Recommended)

**Batch 1: Foundation (Backend)** - COMPLETED
1. 1.2 - Create @stateSpaceEvent decorator - DONE
2. 1.1 - Extend polyTypedObject - DONE
3. 1.3 - Create StateDefinition model - DONE
4. 2.1-2.3 - Backend API endpoints - DONE

**Batch 2: Frontend Models & Services** - COMPLETED
5. 3.1 - StateDefinition TypeScript model - DONE
6. 3.2 - Extend NoCodeState model - DONE (added stateDefinitionId, objectInstanceId, boundObjectClass, boundObjectFieldValues fields)
7. 4.1 - StateDefinition service - DONE (created state-definition.service.ts with full CRUD, caching, and API support)
8. 4.2 - Extend solution state service - DONE (added bindStateToDefinition, bindStateToObjectInstance, updateStateFieldValues, etc.)

**Batch 3: UI Components** - COMPLETED
9. 5.1 - Add toggle to CreateNewClassComponent - DONE
10. 6.1 - StateDefinitionCreator component - DONE (created component with class selection, event method selection, field configuration, preview)

**Batch 4: D3 Overlay Integration** - COMPLETED
11. 7.2 - StateOverlayManager service - DONE
12. 7.3 - CircleStateLayer overlay events - DONE
13. 7.4 - State overlay component - DONE
14. 7.5 - CustomNoCodeComponent integration - DONE

**Batch 5: Polish**
15. 8.1-8.2 - Testing and verification

---

## Implementation Progress

### Batch 4: D3 Overlay Integration - COMPLETED

**Files Created:**
1. `polari-platform-angular/src/app/services/no-code-services/state-overlay-manager.service.ts`
   - Manages overlay component lifecycle
   - Uses getBoundingClientRect() for position calculation
   - Handles create/destroy/hide/show/update operations
   - Tracks active overlays by state name

2. `polari-platform-angular/src/app/components/custom-no-code/state-overlay/state-overlay.component.ts`
   - Angular component rendered inside state circles
   - Class selection with autocomplete
   - Field display configuration (1 or 2 per row)
   - Compact mode for small overlays

3. `polari-platform-angular/src/app/components/custom-no-code/state-overlay/state-overlay.component.html`
   - Header with class label/search
   - Fields section with configurable layout
   - Compact mode indicator

4. `polari-platform-angular/src/app/components/custom-no-code/state-overlay/state-overlay.component.css`
   - Fixed positioning styles
   - Header, fields, compact mode styling
   - Scrollable fields area

**Files Modified:**
1. `polari-platform-angular/src/app/app.module.ts`
   - Added StateOverlayComponent to declarations
   - Added StateOverlayManager to providers

2. `polari-platform-angular/src/app/models/noCode/d3-extensions/CircleStateLayer.ts`
   - Added callback properties for overlay events
   - Added setOnStateOverlayClick(), setOnStateDragStart(), setOnStateDragEnd()
   - Added getStateGroupByName() for overlay positioning
   - Added click handler on overlay-component rect
   - Added drag start/end callback invocations

3. `polari-platform-angular/src/app/components/custom-no-code/custom-no-code.ts`
   - Imported StateOverlayManager and StateOverlayComponent
   - Added stateOverlayManager injection
   - Set ViewContainerRef in ngAfterViewInit
   - Added setupOverlayCallbacks() to configure CircleStateLayer
   - Added handleStateOverlayClick() for overlay creation/toggle
   - Added updateAllOverlayPositions() for zoom/pan/resize
   - Destroy overlays on solution change and component destroy

**How It Works:**
1. Click on white inner rect (overlay-component) in a state circle
2. CircleStateLayer triggers onStateOverlayClick callback
3. CustomNoCodeComponent creates overlay via StateOverlayManager
4. Overlay positions itself using getBoundingClientRect() which handles all transforms
5. On zoom/pan, onZoom calls updateAllOverlayPositions()
6. On state drag, callbacks hide/reposition overlays
7. On solution change, all overlays are destroyed

---

## Key Technical Decisions

### Previous Attempts Analysis

**Existing Components:**
- `NoCodeStateInstanceComponent` - Mat-card with class input and state position display
- `NoCodeStateBorderComponent` - Handles slot positioning with drag
- `OverlayComponentService.addDynamicComponent()` - Appends to document.body with position/size

**What Was Missing:**
1. No connection between D3 state groups and overlay component lifecycle
2. No transformation from SVG coordinates to screen coordinates
3. No handling of zoom/pan affecting overlay positions
4. No event bridge between D3 click and Angular component creation

### Overlay Positioning Strategy

The D3 `rect.overlay-component` is defined in local group coordinates:
```typescript
// In CircleStateLayer.ts lines 479-486:
group.append('rect')
    .classed('overlay-component', true)
    .attr('x', -(1.4 * datapoint.radius) / 2)  // e.g., -70 for radius=100
    .attr('y', -(1.4 * datapoint.radius) / 2)
    .attr('width', 1.4 * datapoint.radius)     // e.g., 140
    .attr('height', 1.4 * datapoint.radius)
```

**To get screen position, use getBoundingClientRect() which applies all transforms:**
```typescript
// This is the KEY - getBoundingClientRect automatically handles:
// 1. The group's translate(cx, cy) transform
// 2. The zoom-container's transform (zoom/pan)
// 3. SVG viewBox scaling

const overlayRect = stateGroup.select('rect.overlay-component').node();
const screenBounds = overlayRect.getBoundingClientRect();

// Now screenBounds has actual screen pixels
this.overlayComponentService.addDynamicComponent(
    StateOverlayComponent,
    {
        x: screenBounds.x,
        y: screenBounds.y,
        width: screenBounds.width,
        height: screenBounds.height
    },
    0,
    this.hostViewContainerRef
);
```

### Overlay Lifecycle Management

Since overlays are appended to document.body, we need to:
1. Track which states have active overlays
2. Destroy overlays when switching solutions
3. Hide/reposition overlays during drag
4. Update overlay positions on zoom/pan

**Proposed StateOverlayManager service methods:**
```typescript
class StateOverlayManager {
    private activeOverlays: Map<string, ComponentRef<StateOverlayComponent>> = new Map();

    createOverlayForState(stateName: string, stateGroup: SVGGElement): void;
    destroyOverlayForState(stateName: string): void;
    destroyAllOverlays(): void;
    updateOverlayPosition(stateName: string, stateGroup: SVGGElement): void;
    updateAllOverlayPositions(): void;  // Called on zoom/pan
    hideOverlayForState(stateName: string): void;    // During drag
    showOverlayForState(stateName: string): void;    // After drag
}
```

### Zoom Handling Options
1. **Fixed-size overlays** - Reposition on zoom, maintain readable size
2. **Scaled overlays** - Scale with D3 transform (may become too small/large)

Recommendation: Fixed-size overlays that reposition, with visibility threshold (hide when too zoomed out).

### Field Display Layout
```typescript
// Single field per row
<div class="field-row single">
    <mat-form-field>...</mat-form-field>
</div>

// Two fields per row
<div class="field-row double">
    <mat-form-field>...</mat-form-field>
    <mat-form-field>...</mat-form-field>
</div>
```

---

## Files to Create
1. `polari-framework/polariDataTyping/stateSpaceDecorators.py`
2. `polari-framework/polariDataTyping/stateDefinition.py`
3. `polari-platform-angular/src/app/models/noCode/StateDefinition.ts`
4. `polari-platform-angular/src/app/services/no-code-services/state-definition.service.ts`
5. `polari-platform-angular/src/app/services/no-code-services/state-overlay-manager.service.ts`
6. `polari-platform-angular/src/app/components/state-definition-creator/*`
7. `polari-platform-angular/src/app/components/custom-no-code/state-overlay/*`

## Files to Modify
1. `polari-framework/polariDataTyping/polyTyping.py`
2. `polari-framework/polariApiServer/polariServerBaseRoutes.py`
3. `polari-platform-angular/src/app/models/noCode/NoCodeState.ts`
4. `polari-platform-angular/src/app/services/no-code-services/no-code-solution-state.service.ts`
5. `polari-platform-angular/src/app/components/create-new-class/*`
6. `polari-platform-angular/src/app/models/noCode/d3-extensions/CircleStateLayer.ts`
7. `polari-platform-angular/src/app/components/custom-no-code/custom-no-code.ts`

---

## Session 2 Implementation Details (Batch 2 & 3 Completion)

### NoCodeState Model Extensions

**File:** `polari-platform-angular/src/app/models/noCode/NoCodeState.ts`

Added state-space object system fields:
```typescript
// Links this state to a StateDefinition template
stateDefinitionId?: string;
// Links to an actual object instance when this state represents a bound object
objectInstanceId?: string;
// The class name of the bound object (populated from StateDefinition.sourceClassName)
boundObjectClass?: string;
// Field values for the bound object instance
boundObjectFieldValues?: { [fieldName: string]: any };
```

Added helper methods:
- `bindToStateDefinition(stateDefinitionId, sourceClassName)` - Bind state to definition
- `bindToObjectInstance(objectInstanceId, fieldValues?)` - Bind to object instance
- `updateFieldValue(fieldName, value)` - Update single field value
- `getFieldValue(fieldName)` - Get field value
- `isBoundToStateSpace()` - Check if bound to state-space
- `hasBoundInstance()` - Check if has object instance
- `clearStateSpaceBindings()` - Clear all bindings

### StateDefinition Service

**File:** `polari-platform-angular/src/app/services/no-code-services/state-definition.service.ts`

Features:
- In-memory caching with localStorage persistence
- Integration with StateSpaceClassRegistry for built-in classes
- Full CRUD operations: create, read, update, delete state definitions
- Observable streams for reactive updates (`stateDefinitions$`, `stateSpaceClasses$`)
- Factory methods for creating definitions from built-in classes
- API endpoint support for backend integration (when available)

Key methods:
- `getAllStateDefinitions()` / `getStateDefinitionById(id)`
- `getStateDefinitionsForClass(className)`
- `createStateDefinition(definition)` / `updateStateDefinition(id, updates)`
- `deleteStateDefinition(id)`
- `getAllStateSpaceClasses()` / `getStateSpaceConfig(className)`
- `getBuiltInClassMetadata(className)` / `getAllBuiltInClasses()`
- `createDefinitionFromBuiltInClass(className, eventMethodName?)`
- API methods: `fetchStateDefinitionsFromApi()`, `saveStateDefinitionToApi()`, etc.

### NoCodeSolutionStateService Extensions

**File:** `polari-platform-angular/src/app/services/no-code-services/no-code-solution-state.service.ts`

Added state-space object association methods:
- `bindStateToDefinition(solutionName, stateName, stateDefinitionId, sourceClassName)`
- `bindStateToObjectInstance(solutionName, stateName, objectInstanceId, fieldValues?)`
- `updateStateFieldValues(solutionName, stateName, fieldValues)`
- `getStateBoundObjectData(solutionName, stateName)` - Returns binding info
- `getBoundStates(solutionName)` - Get all bound states in solution
- `clearStateBindings(solutionName, stateName)`
- `associateStateWithDefinition(solutionName, stateName, definition)` - Full association

### StateDefinitionCreator Component

**Files:**
- `polari-platform-angular/src/app/components/custom-no-code/state-definition-creator/state-definition-creator.component.ts`
- `polari-platform-angular/src/app/components/custom-no-code/state-definition-creator/state-definition-creator.component.html`
- `polari-platform-angular/src/app/components/custom-no-code/state-definition-creator/state-definition-creator.component.css`

Features:
1. **Class Selection** - Autocomplete with category grouping from StateSpaceClassRegistry
2. **Event Method Selection** - Choose which @stateSpaceEvent method to use
3. **Auto-generated Slots** - Input/output slots generated from event method signature
4. **Display Fields Configuration** - Toggle visibility, reorder, configure 1 or 2 per row
5. **Appearance Settings** - Category, icon, color customization
6. **Live Preview** - Shows how the state will look with current settings
7. **Edit Mode Support** - Can edit existing definitions

Component inputs/outputs:
- `@Input() existingDefinition?: StateDefinition` - For editing mode
- `@Output() definitionSaved = EventEmitter<StateDefinition>`
- `@Output() cancelled = EventEmitter<void>`

### Module Updates

**File:** `polari-platform-angular/src/app/app.module.ts`
- Added StateDefinitionCreatorComponent to declarations
- Added StateDefinitionService to providers

**File:** `polari-platform-angular/src/app/material/material.module.ts`
- Added MatButtonToggleModule (for fields per row toggle)
- Added MatSlideToggleModule (for field visibility toggles)

---

## Next Steps (Batch 5: Testing & Integration)

1. **Test StateDefinitionCreator Component**
   - Create sample state definitions
   - Verify field configuration persists
   - Test edit mode functionality

2. **Test State-Object Binding Flow**
   - Bind a state to a definition via overlay
   - Verify field values persist across session
   - Test binding/unbinding lifecycle

3. **Integration with D3 Overlay**
   - Trigger StateDefinitionCreator from overlay
   - Update overlay display when definition changes
   - Handle field value editing in overlay

4. **End-to-End Testing**
   - Create a no-code solution with bound states
   - Verify data flow between states via connectors
   - Test execution with bound object instances

---

## Session 3: UI Integration (Sidebar & Menu Buttons)

### StateToolSidebarComponent

**Files:**
- `polari-platform-angular/src/app/components/custom-no-code/state-tool-sidebar/state-tool-sidebar.component.ts`
- `polari-platform-angular/src/app/components/custom-no-code/state-tool-sidebar/state-tool-sidebar.component.html`
- `polari-platform-angular/src/app/components/custom-no-code/state-tool-sidebar/state-tool-sidebar.component.css`

**Features:**
1. Lists all available state-space classes (built-in + custom definitions)
2. Groups items by category with expandable sections
3. Search/filter functionality
4. Click or drag items to create new state instances
5. Collapsible sidebar with toggle button
6. "Create Definition" button to open creator panel

**Component API:**
- `@Input() isExpanded: boolean` - Sidebar expansion state
- `@Output() createStateFromDefinition` - Emits StateToolItem when clicked
- `@Output() openDefinitionCreator` - Opens the definition creator panel
- `@Output() toggleExpanded` - Sidebar toggle event

### NoCodeMenu Updates

**File:** `polari-platform-angular/src/app/components/custom-no-code/no-code-menu/`

Added:
- "Create Definition" button that opens the StateDefinitionCreator panel
- `@Output() openDefinitionCreator` event emitter

### CustomNoCodeComponent Updates

**File:** `polari-platform-angular/src/app/components/custom-no-code/custom-no-code.ts`

Added properties:
- `sidebarExpanded: boolean` - Sidebar state
- `showDefinitionCreator: boolean` - Panel visibility
- `editingDefinition: StateDefinition | undefined` - For edit mode

Added methods:
- `onSidebarToggle(expanded)` - Handle sidebar toggle
- `onCreateStateFromDefinition(item)` - Create state from tool item
- `onOpenDefinitionCreator()` - Open creator panel
- `closeDefinitionCreator()` - Close creator panel
- `onDefinitionSaved(definition)` - Handle saved definition
- `editDefinition(definition)` - Open creator for editing

### Layout Changes

**File:** `polari-platform-angular/src/app/components/custom-no-code/custom-no-code.html`

Structure:
```
no-code-container
├── menu-container (top bar)
├── main-content-area (flex row)
│   ├── app-state-tool-sidebar
│   └── canvas-wrapper (d3 graph)
├── definition-creator-panel (slide-in from right)
└── panel-backdrop
```

**File:** `polari-platform-angular/src/app/components/custom-no-code/custom-no-code.css`

Added styles for:
- `.main-content-area` - Flex container for sidebar + canvas
- `.definition-creator-panel` - Sliding panel from right
- `.panel-header`, `.panel-content` - Panel layout
- `.panel-backdrop` - Overlay behind panel

### Testing Instructions

To test the new features:

1. Start the dev server: `npm run start`
2. Navigate to the no-code editor
3. You should see:
   - **Left sidebar** with state tools grouped by category
   - **"Create Definition"** buttons in both the sidebar and top menu
4. Test creating states:
   - Click on any item in the sidebar (e.g., "For Loop") to create a state instance
   - The state should appear in the D3 canvas
5. Test the Definition Creator:
   - Click "Create Definition" to open the sliding panel
   - Select a class, configure fields, and save
   - The new definition should appear in the sidebar under its category
