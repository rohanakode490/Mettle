# Minimalist Flutter UI Patterns

## 1. Minimal Card
Avoid `Card` widget's default elevation. Use a `Container` with a light border.

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey[200]!),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Title', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('Subtitle', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
    ],
  ),
)
```

## 2. Focused Action Button
The primary action should be a full-width button at the bottom or a very prominent center button.

```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 56),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  child: const Text('LET\'S GO'),
)
```

## 3. Clean Empty States
Use simple icons and motivating text. Avoid cluttered "Add something" lists.

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.auto_awesome, size: 48, color: Colors.blue[200]),
      const SizedBox(height: 16),
      Text('Empty space, full of potential.', style: TextStyle(color: Colors.grey[400])),
      const SizedBox(height: 24),
      TextButton(onPressed: () {}, child: const Text('Add your first item')),
    ],
  ),
)
```
