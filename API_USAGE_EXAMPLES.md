# Vehicle Buy/Sell Transaction System - API Usage Examples

## 🚗 Complete Buy/Sell Workflow

### 1. Purchase Vehicle from Customer
**Endpoint:** `POST /api/buy-sell/purchase`

```bash
curl -X POST http://localhost:8080/api/buy-sell/purchase \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "customer-uuid-here",
    "car_id": "car-uuid-here", 
    "amount": 150000000,
    "payment_method": "cash",
    "notes": "Negotiated price - Honda Civic 2018, good condition",
    "created_by": "admin-user-uuid"
  }'
```

**Response:** Auto-generates purchase invoice `PUR-20250730-001` and sets car status to "in_repair"

### 2. Upload Vehicle Photos (9 Angles Support)
**Endpoint:** `POST /api/photos/upload`

```bash
# Front view
curl -X POST http://localhost:8080/api/photos/upload \
  -F "entity_type=car" \
  -F "entity_id=car-uuid" \
  -F "photo_type=front" \
  -F "caption=Front view - clean exterior" \
  -F "uploaded_by=user-uuid" \
  -F "file=@photos/front_view.jpg"

# Interior view  
curl -X POST http://localhost:8080/api/photos/upload \
  -F "entity_type=car" \
  -F "entity_id=car-uuid" \
  -F "photo_type=interior" \
  -F "caption=Interior - leather seats, clean dashboard" \
  -F "uploaded_by=user-uuid" \
  -F "file=@photos/interior.jpg"

# Engine bay
curl -X POST http://localhost:8080/api/photos/upload \
  -F "entity_type=car" \
  -F "entity_id=car-uuid" \
  -F "photo_type=engine" \
  -F "caption=Engine bay - well maintained" \
  -F "uploaded_by=user-uuid" \
  -F "file=@photos/engine.jpg"

# Damage documentation
curl -X POST http://localhost:8080/api/photos/upload \
  -F "entity_type=car" \
  -F "entity_id=car-uuid" \
  -F "photo_type=damage" \
  -F "caption=Small scratch on right side door" \
  -F "uploaded_by=user-uuid" \
  -F "file=@photos/scratch_right_door.jpg"
```

### 3. Set Primary Photo for Cashier Thumbnail
**Endpoint:** `POST /api/photos/primary/{entity_type}/{entity_id}/{photo_id}`

```bash
curl -X POST http://localhost:8080/api/photos/primary/car/car-uuid/front-photo-uuid
```

### 4. Sell Vehicle to Customer
**Endpoint:** `POST /api/buy-sell/sell`

```bash
curl -X POST http://localhost:8080/api/buy-sell/sell \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "buyer-customer-uuid",
    "car_id": "car-uuid",
    "amount": 175000000,
    "discount_amount": 5000000,
    "payment_method": "transfer", 
    "notes": "Sale to Mr. Budi - 5% loyalty discount applied",
    "created_by": "salesperson-uuid"
  }'
```

**Response:** Creates sales invoice `SAL-20250730-004`, transaction record, and updates car status to "sold"

## 📋 Invoice Management

### List All Purchase Invoices
```bash
curl http://localhost:8080/api/buy-sell/purchases?page=1&limit=10
```

### List All Sales Invoices  
```bash
curl http://localhost:8080/api/buy-sell/sales?page=1&limit=10
```

### Mark Invoice as Paid (with Transfer Proof)
```bash
curl -X POST http://localhost:8080/api/invoices/invoice-uuid/paid \
  -H "Content-Type: application/json" \
  -d '{
    "payment_proof": "/uploads/payments/transfer_proof_20250730.jpg"
  }'
```

### Get Invoice by Number
```bash
curl "http://localhost:8080/api/invoices/number?number=PUR-20250730-001"
```

## 📸 Photo Gallery Features

### Get All Photos for a Car
```bash
curl http://localhost:8080/api/photos/entity/car/car-uuid
```

### Get Primary Photo (for Thumbnail)
```bash  
curl http://localhost:8080/api/photos/primary/car/car-uuid
```

### Get Before/After Repair Photos
```bash
# Before repair
curl http://localhost:8080/api/photos/type/car/car-uuid/before

# After repair  
curl http://localhost:8080/api/photos/type/car/car-uuid/after
```

### Get Damage Documentation
```bash
curl http://localhost:8080/api/photos/type/car/car-uuid/damage
```

## 🎯 Business Workflow Examples

### Complete Purchase → Repair → Sale Cycle

1. **Buy from Customer**: Creates `PUR-20250730-001` invoice
2. **Upload Photos**: Document current condition (9 angles)
3. **Create Work Order**: Assign to mechanic for repairs
4. **Update Progress**: 0% → 50% → 100% complete
5. **Upload After Photos**: Document completed repairs  
6. **Set Primary Photo**: Best angle for sales display
7. **Sell to New Customer**: Creates `SAL-20250730-004` invoice
8. **Generate Receipt**: PDF ready for WhatsApp sharing

### Customer Management Integration

- **Auto Customer Codes**: CR-0001, CR-0002, CR-0003...
- **Quick Search**: Find customer by typing "0812" → shows all with that phone number
- **Transaction History**: View all purchases/sales for customer relationship management

## 💰 Payment Method Support

- **Cash**: Direct payment, immediate completion
- **Transfer**: Upload payment proof image, mark as paid when confirmed  
- **Credit**: Extended payment terms with due date tracking

## 🔄 Response Format

All endpoints return consistent JSON:

```json
{
  "success": true,
  "message": "Vehicle purchased successfully",
  "data": {
    "invoice": {
      "id": "uuid",
      "invoice_number": "PUR-20250730-001",
      "invoice_type": "purchase",
      "amount": 150000000,
      "total_amount": 150000000,
      "payment_method": "cash",
      "status": "draft"
    },
    "car": {
      "id": "uuid", 
      "brand": "Honda",
      "model": "Civic",
      "year": 2018,
      "status": "in_repair"
    }
  }
}
```

This implementation provides complete vehicle dealership buy/sell functionality with professional invoice management and comprehensive photo documentation, maintaining full compatibility with the existing TypeScript system while adding essential missing features.