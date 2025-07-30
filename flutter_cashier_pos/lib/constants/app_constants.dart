class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8080/api';
  static const String authEndpoint = '/auth/login';
  static const String customersEndpoint = '/customers';
  static const String carsEndpoint = '/cars';
  static const String buyEndpoint = '/buy-sell/purchase';
  static const String sellEndpoint = '/buy-sell/sell';
  static const String invoicesEndpoint = '/invoices';
  static const String photosEndpoint = '/photos';
  static const String sparepartsEndpoint = '/spareparts';
  static const String workOrdersEndpoint = '/work-orders';
  
  // Local Storage
  static const String authBox = 'auth_box';
  static const String settingsBox = 'settings_box';
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
  
  // UI Constants
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  
  // Colors (modern gradient-based design)
  static const int primaryColorValue = 0xFF6366F1; // Modern indigo
  static const int primaryDarkValue = 0xFF4F46E5; // Deeper indigo
  static const int accentColorValue = 0xFF10B981; // Modern emerald
  static const int errorColorValue = 0xFFEF4444; // Modern red
  static const int warningColorValue = 0xFFF59E0B; // Modern amber
  static const int surfaceColorValue = 0xFFF8FAFC; // Light background
  static const int cardColorValue = 0xFFFFFFFF; // Pure white for cards
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // File upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Grid layout
  static const int tabletGridColumns = 4;
  static const int mobileGridColumns = 2;
  
  // Payment methods
  static const List<String> paymentMethods = ['cash', 'transfer', 'credit'];
  
  // Photo types
  static const List<String> photoTypes = [
    'front', 'back', 'left', 'right', 
    'interior', 'engine', 'dashboard', 
    'damage', 'before', 'after'
  ];
  
  // User roles
  static const String cashierRole = 'cashier';
  static const String adminRole = 'admin';
  static const String managerRole = 'manager';
  static const String salespersonRole = 'salesperson';
  static const String mechanicRole = 'mechanic';
}