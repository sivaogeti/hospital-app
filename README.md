# 

# We already have starter files for pages in this repo—please enhance or replace if needed:

# \- `lib/.../stock\_page.dart`

# \- `lib/.../health\_profiles\_page.dart`

# \- `lib/.../reports\_page.dart`

# 

# ---

# 

# \## Overflow Note (Flutter)

# Avoid “\*\*BOTTOM OVERFLOWED BY XX PIXELS\*\*” on tiles:

# \- Wrap scrollable containers with `SingleChildScrollView`.

# \- Inside `Column`, place grid/list in `Expanded` (or `Flexible`).

# \- Use fixed tile heights or `AspectRatio` so icons/text don’t exceed card bounds.

# 

# ---

# 

# \## Acceptance Criteria

# \- Dashboard shows tiles for \*\*Inventory/Stock\*\*, \*\*Health Profiles\*\*, \*\*Reports\*\*.

# \- Each page fully functional per spec above.

# \- No overflow warnings at common phone sizes.

# \- `flutter analyze` passes.

# \- Basic unit tests: model serialization + one service mock.

# 

# ---

# 

# \## How to Run

# ```bash

# flutter pub get

# flutter analyze

# flutter run



