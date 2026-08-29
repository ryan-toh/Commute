# Commute code preferences

- Target iOS 17+. Prefer modern Observation APIs: `@Observable`, `@State`, and typed `@Environment`. Do not use `@StateObject` or older APIs where a modern equivalent exists.
- Keep domain models framework-independent. Do not put Core Location or MapKit types in models; convert at service/adaptor or presentation boundaries.
- Avoid `Any`, `AnyObject`, and weakly typed abstractions. Prefer focused, typed protocols.
- View models own meaningful observable state and the operations that mutate it. Name them after their precise responsibility (for example, `MapViewModel` for map-camera state).
- A view may modify only data that belongs to its own responsibility. Put shared, cross-feature, or lifecycle-driven mutations at the appropriate feature host or composition boundary.
- Coordinators compose existing models and route cross-feature actions. A coordinator that owns no observable state is not a view model.
- Leaf views render explicit input and emit explicit user actions. Keep them free of business logic and environment dependencies.
- Container views may own local UI state that only matters within their subtree (for example, map camera state). Move non-trivial presentation behaviour into a focused local view model.
- Resolve app-owned dependencies at a feature host/composition boundary. Pass grouped display state and actions to children instead of passing many raw models or having leaf views read the environment.
- Use `DisplayState` for immutable UI snapshots and `Actions` for user-intent callbacks. Do not create duplicate state owners merely to avoid passing data.
- Keep view and file names responsibility-led and hierarchy-led. Folder structure should make feature composition clear.
- Put UI constants and copy in `Preferences`; do not leave magic values in views or view models.
- Prefer small, cohesive files and extract a subview when it has a distinct responsibility—not simply to split lines of code.
