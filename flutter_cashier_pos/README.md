# Car Showroom POS - Cashier Mobile App 📱

A modern Flutter application designed specifically for cashiers in car showroom dealerships. This tablet-optimized POS system provides a complete vehicle sales transaction workflow with customer management and invoice generation.

## ✨ Features

### 🔐 **Authentication**
- **Cashier-Only Access**: Secure login restricted to cashier role users
- **JWT Authentication**: Token-based authentication with auto-logout
- **Session Management**: Persistent login with automatic token refresh

### 🚗 **Vehicle Sales Management**
- **Inventory Browser**: Grid view of available vehicles with photo thumbnails
- **Advanced Search**: Filter by brand, model, year, price, fuel type, transmission
- **Vehicle Details**: Complete vehicle information with photo gallery
- **Real-time Availability**: Live inventory updates

### 👥 **Customer Management**
- **Customer Search**: Quick search by name, phone, email, or customer code
- **Phone Prefix Search**: One-tap search by common phone prefixes (08, 081, etc.)
- **Customer Profiles**: Complete customer information with auto-generated codes (CR-0001, CR-0002...)
- **Quick Customer Creation**: In-flow customer registration during sales

### 💰 **Sales Transaction Workflow**
- **Complete Sales Process**: Customer selection → Vehicle selection → Payment processing
- **Multiple Payment Methods**: 
  - Cash payments
  - Bank transfers 
  - Credit/installment plans
- **Automatic Calculations**: Real-time total calculation with discount support
- **Invoice Generation**: Auto-numbered invoices (SAL-YYYYMMDD-XXX format)

### 📋 **Invoice Management**
- **Invoice History**: Complete transaction history with search and filters
- **Status Tracking**: Draft, Paid, Pending, Cancelled status management
- **Payment Confirmation**: Mark invoices as paid with payment proof
- **Daily Reports**: Today's transactions tab for quick overview

### 📱 **Modern UI/UX**
- **Tablet Optimized**: Responsive design optimized for tablet POS systems
- **Material Design 3**: Modern, clean interface with consistent theming
- **Grid Layouts**: Efficient use of screen space with adaptive grids
- **Quick Actions**: Dashboard shortcuts for common operations
- **Real-time Updates**: Live data refresh and state management

## 🏗️ Architecture

### **Clean Architecture Pattern**
```
lib/
├── models/           # Data models (Customer, Car, Invoice, etc.)
├── services/         # API integration services
├── providers/        # State management (Riverpod)
├── screens/          # Main application screens
├── widgets/          # Reusable UI components
├── utils/            # Utilities and themes
└── constants/        # App constants and configuration
```

### **Technology Stack**
- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **HTTP Client**: Dio for API calls
- **Local Storage**: Hive for caching
- **Image Handling**: Cached Network Image
- **Navigation**: Go Router
- **Responsive Design**: ScreenUtil + Responsive Framework

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Android device/emulator or iOS device/simulator

### **Installation**

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_cashier_pos
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   Update the base URL in `lib/constants/app_constants.dart`:
   ```dart
   static const String baseUrl = 'http://your-api-server:8080/api';
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🔌 API Integration

### **Backend Requirements**
The app integrates with the Golang backend API with these endpoints:

#### **Authentication**
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user

#### **Customer Management**
- `GET /api/customers` - List customers with pagination
- `POST /api/customers` - Create new customer
- `PUT /api/customers/{id}` - Update customer
- `GET /api/customers/search` - Search customers

#### **Vehicle Management**
- `GET /api/cars` - List available vehicles
- `GET /api/cars/{id}` - Get vehicle details
- `GET /api/cars/brands` - Get available brands
- `GET /api/cars/models` - Get models by brand

#### **Sales Transactions**
- `POST /api/buy-sell/sell` - Create sale transaction
- `GET /api/buy-sell/sales` - List sales invoices
- `POST /api/invoices/{id}/paid` - Mark invoice as paid

#### **Photo Management**
- `GET /api/photos/entity/{type}/{id}` - Get entity photos
- `GET /api/photos/primary/{type}/{id}` - Get primary photo

### **Response Format**
All API responses follow this consistent format:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {...},
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

## 📊 Business Workflow

### **Complete Sales Process**

1. **Customer Selection**
   - Search existing customers by phone/name
   - Quick phone prefix search (08, 081, 082...)
   - Create new customer if not found

2. **Vehicle Selection**
   - Browse available inventory
   - Filter by brand, model, year, price
   - View vehicle details and photos
   - Check availability status

3. **Sales Transaction**
   - Enter sale amount (auto-filled from vehicle price)
   - Apply optional discounts
   - Select payment method (cash/transfer/credit)
   - Add transaction notes

4. **Invoice Generation**
   - Auto-generated invoice number (SAL-20250730-XXX)
   - Complete transaction details
   - Payment method and status
   - Print/share option

5. **Payment Processing**
   - Mark as paid for cash transactions
   - Upload payment proof for transfers
   - Track payment status

## 🎨 UI/UX Features

### **Dashboard**
- Welcome message with user info
- Quick action buttons for main functions
- Sales statistics cards
- Recent transactions list

### **Sales Screen**
- Customer selection with search
- Vehicle grid with photos and pricing
- Payment method selector with icons
- Real-time total calculation
- Success confirmation with print option

### **Customer Screen**
- Paginated customer list
- Advanced search with filters
- Quick phone prefix search
- In-line customer creation
- Customer profile cards with codes

### **Inventory Screen**
- Responsive vehicle grid
- Advanced filtering dialog
- Vehicle details with photo gallery
- Status indicators and pricing
- Load more pagination

### **Invoice Screen**
- Tabbed interface (All/Today)
- Search by invoice number
- Status filters and date ranges
- Detailed invoice view
- Payment status management

## 🔧 Configuration

### **App Constants**
Edit `lib/constants/app_constants.dart` for:
- API endpoints and base URL
- Pagination settings
- File upload limits
- Color scheme values
- Payment methods
- Photo types

### **Theme Customization**
Modify `lib/utils/app_theme.dart` for:
- Color schemes and gradients
- Typography styles
- Component themes
- Responsive breakpoints

## 📱 Device Support

### **Tablet Optimization**
- **Primary Target**: 10-12 inch tablets (1024x768 design)
- **Grid Layouts**: 2-4 columns based on screen size
- **Touch-Friendly**: Large tap targets and spacing
- **Landscape Orientation**: Optimized for landscape use

### **Phone Compatibility**
- **Responsive Design**: Adapts to smaller screens
- **Single Column**: Mobile layouts for phone screens
- **Portrait Support**: Vertical orientation support

## 🔒 Security Features

- **Role-Based Access**: Only cashier role users can access
- **JWT Token Management**: Secure token storage and refresh
- **Session Timeout**: Automatic logout after inactivity
- **Input Validation**: Client-side and server-side validation
- **Secure Storage**: Encrypted local data storage

## 🚀 Deployment

### **Development Build**
```bash
flutter run --debug
```

### **Production Build**
```bash
# Android APK
flutter build apk --release

# Android Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### **Testing**
```bash
# Run tests
flutter test

# Widget tests
flutter test test/widget_test.dart
```

## 📝 Usage Examples

### **Daily Cashier Workflow**

1. **Login** with cashier credentials
2. **Check Dashboard** for today's stats
3. **Process New Sale**:
   - Search/create customer
   - Select vehicle from inventory
   - Enter sale details
   - Choose payment method
   - Generate invoice
4. **Manage Payments**:
   - Mark cash payments as paid
   - Upload transfer proofs
   - Track pending payments
5. **View Reports**:
   - Today's transactions
   - Invoice history
   - Customer information

### **Common Operations**

- **Quick Customer Search**: Type "081" → see all customers with 081 phone numbers
- **Vehicle Filter**: Filter by Honda, 2018-2022, under 200M rupiah
- **Bulk Operations**: Mark multiple invoices as paid
- **Print Invoices**: Generate PDF receipts for customers

## 🔄 Updates and Maintenance

### **Regular Updates**
- Pull latest vehicle inventory
- Sync customer data
- Update payment statuses
- Refresh user authentication

### **Data Management**
- Automatic cache cleanup
- Image optimization
- Local storage management
- Offline data handling

## 📞 Support

For technical support or feature requests:
- Check API documentation
- Verify backend connectivity
- Update Flutter dependencies
- Review error logs and debug output

---

**Car Showroom POS - Modern, Efficient, User-Friendly** 🚗💼📱