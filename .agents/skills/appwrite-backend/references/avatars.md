# Avatars

## Website Screenshots

Capture screenshot of any URL.

```dart
// Dart
final screenshot = await avatars.getScreenshot(
    url: 'https://example.com',
    width: 1280,
    height: 720,
);
```

```python
# Python
screenshot = avatars.get_screenshot(
    url='https://example.com',
    width=1280,
    height=720,
)
```

```typescript
// TypeScript
const screenshot = await avatars.getScreenshot({
    url: 'https://example.com',
    width: 1280,
    height: 720,
});
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `url` | Target URL (required) | - |
| `width` | Screenshot width | 1920 |
| `height` | Screenshot height | 1080 |

### Use Cases

- Link previews
- OG image gen
- Competitor monitor
- Docs

---

## Initials Avatars

Gen avatars from user names.

```dart
// Dart
final avatar = await avatars.getInitials(
    name: 'John Doe',
    width: 100,
    height: 100,
    background: 'ff5733',
);
```

```python
# Python
avatar = avatars.get_initials(
    name='John Doe',
    width=100,
    height=100,
    background='ff5733',
)
```

```typescript
// TypeScript
const avatar = await avatars.getInitials({
    name: 'John Doe',
    width: 100,
    height: 100,
    background: 'ff5733',
});
```

---

## Flags

Country flag images by ISO code.

```dart
// Dart - US flag
import 'package:dart_appwrite/enums.dart';

final flag = await avatars.getFlag(code: Flag.unitedStates, width: 100);
```

---

## Credit Card Icons

```dart
// Dart - Visa icon
final icon = await avatars.getCreditCard(code: CreditCard.visa, width: 100);
```

`CreditCard`: `americanExpress`, `argencard`, `cabal`, `cencosud`, `dinersClub`, `discover`, `elo`, `hipercard`, `jCB`, `mastercard`, `naranja`, `tarjetaShopping`, `unionPay`, `visa`, `mIR`, `maestro`, `rupay`

---

## Browser Icons

```dart
// Dart
final icon = await avatars.getBrowser(code: Browser.googleChrome, width: 50);
```

`Browser`: `avantBrowser`, `androidWebViewBeta`, `googleChrome`, `googleChromeIOS`, `googleChromeMobile`, `chromium`, `mozillaFirefox`, `safari`, `mobileSafari`, `microsoftEdge`, `microsoftEdgeIOS`, `operaMini`, `opera`, `operaNext`

---

## Favicon Fetch

Get favicon from any domain.

```dart
// Dart
final favicon = await avatars.getFavicon(url: 'https://github.com');
```

---

## QR Codes

Gen QR from text/URL.

```dart
// Dart
final qr = await avatars.getQR(
    text: 'https://example.com/link',
    size: 300,
    margin: 2,
);
```

```python
# Python
qr = avatars.get_qr(
    text='https://example.com/link',
    size=300,
    margin=2,
)
```

```typescript
// TypeScript
const qr = await avatars.getQR({
    text: 'https://example.com/link',
    size: 300,
    margin: 2,
});
```

---

## Image Avatars

Gen placeholder images.

```dart
// Dart - Placeholder
final image = await avatars.getImage(
    url: 'https://picsum.photos/200',
    width: 200,
    height: 200,
);
```

---

## Performance Tips

1. **Cache avatars** - URLs deterministic
2. **Use CDN** - serve from edge
3. **Size right** - match output dim to display size
4. **Batch w/ SSR** - pre-gen for SSR pages

---

## Related

- Storage for custom avatars
- Functions for custom gen
