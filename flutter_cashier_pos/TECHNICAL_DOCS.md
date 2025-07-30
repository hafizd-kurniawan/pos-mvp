# Flutter Cashier POS - Technical Documentation

## API Integration Examples

### Customer Search by Phone
```dart
// Quick search by phone prefix
final response = await customerService.searchCustomersByPhone("081");
if (response.isSuccess) {
  final customers = response.data; // List<Customer>
  // Display customers starting with 081
}
```

### Create New Sale Transaction
```dart
final saleRequest = CreateSaleRequest(
  customerId: selectedCustomer.id,
  carId: selectedCar.id,
  amount: 150000000.0, // 150 million rupiah
  discountAmount: 5000000.0, // 5 million discount
  paymentMethod: 'cash',
  notes: 'Customer loyalty discount applied',
  createdBy: currentUser.id,
);

final response = await salesService.createSale(saleRequest);
if (response.isSuccess) {
  final invoice = response.data; // Generated invoice with SAL-20250730-001 number
}
```

### Vehicle Inventory Search
```dart
final response = await carService.searchCars(
  brand: 'Honda',
  yearFrom: 2018,
  yearTo: 2022,
  priceFrom: 100000000.0,
  priceTo: 200000000.0,
  page: 1,
  limit: 20,
);
```

## State Management with Riverpod

### Customer Provider
```dart
final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>((ref) {
  return CustomerNotifier(ref.read(customerServiceProvider));
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final CustomerService _customerService;
  
  CustomerNotifier(this._customerService) : super(const AsyncValue.loading());
  
  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    final response = await _customerService.getCustomers();
    if (response.isSuccess) {
      state = AsyncValue.data(response.data!);
    } else {
      state = AsyncValue.error(response.message, StackTrace.current);
    }
  }
}
```

## Responsive Design Implementation

### Tablet Grid Layout
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ResponsiveBreakpoints.of(context).isTablet ? 3 : 2,
    crossAxisSpacing: 12.w,
    mainAxisSpacing: 12.h,
    childAspectRatio: 0.75,
  ),
  itemBuilder: (context, index) => CarInventoryCard(car: cars[index]),
)
```

### Screen Size Adaptation
```dart
class ResponsiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1024, 768), // Tablet design base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          ],
        );
      },
    );
  }
}
```

## Custom Widgets

### Loading Overlay
```dart
LoadingOverlay(
  isLoading: isProcessing,
  loadingText: 'Processing sale...',
  child: SalesForm(),
)
```

### Payment Method Selector
```dart
PaymentMethodSelector(
  selectedMethod: paymentMethod,
  onMethodChanged: (method) {
    setState(() => paymentMethod = method);
  },
)
```

## Error Handling

### API Error Management
```dart
try {
  final response = await apiCall();
  if (response.isSuccess) {
    // Handle success
  } else {
    _showErrorSnackBar(response.message);
  }
} catch (e) {
  _showErrorSnackBar('Network error: $e');
}
```

### Form Validation
```dart
TextFormField(
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field is required';
    }
    if (value.length < 3) {
      return 'Minimum 3 characters';
    }
    return null;
  },
)
```

## Performance Optimizations

### Image Caching
```dart
CachedNetworkImage(
  imageUrl: photoService.getPhotoUrl(car.primaryPhotoUrl!),
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheHeight: 200,
  memCacheWidth: 300,
)
```

### Pagination Implementation
```dart
ListView.builder(
  itemCount: items.length + (hasMoreData ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == items.length) {
      return LoadMoreButton(onPressed: loadMoreData);
    }
    return ItemWidget(item: items[index]);
  },
)
```

## Testing Examples

### Widget Testing
```dart
testWidgets('Customer card displays correctly', (WidgetTester tester) async {
  final customer = Customer(
    id: '1',
    name: 'John Doe',
    phone: '081234567890',
    customerCode: 'CR-0001',
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: CustomerCard(
        customer: customer,
        onTap: () {},
      ),
    ),
  );
  
  expect(find.text('John Doe'), findsOneWidget);
  expect(find.text('081234567890'), findsOneWidget);
  expect(find.text('CR-0001'), findsOneWidget);
});
```

### Service Testing
```dart
test('Customer service returns correct data', () async {
  final mockClient = MockClient();
  final customerService = CustomerService(client: mockClient);
  
  when(mockClient.get(any)).thenAnswer((_) async => 
    http.Response('{"success": true, "data": []}', 200));
  
  final response = await customerService.getCustomers();
  
  expect(response.isSuccess, true);
  expect(response.data, isA<List<Customer>>());
});
```

## Build Configuration

### Android Build
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 33
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            useProguard true
        }
    }
}
```

### iOS Configuration
```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <key>CFBundleDisplayName</key>
    <string>Car Showroom POS</string>
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to capture payment proofs</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to upload images</string>
</dict>
```

## Deployment Pipeline

### CI/CD Example (GitHub Actions)
```yaml
name: Flutter CI/CD
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
    - run: flutter pub get
    - run: flutter test
    - run: flutter analyze
    
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v2
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

## Security Best Practices

### Token Storage
```dart
class SecureStorage {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> storeToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
  
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
```

### Input Sanitization
```dart
String sanitizeInput(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'[<>\"\'%;()&+]'), '')
      .substring(0, min(input.length, 255));
}
```

This documentation provides the technical implementation details needed to understand, maintain, and extend the Flutter cashier POS application.