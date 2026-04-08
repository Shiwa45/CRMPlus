from django.db import models
from django.conf import settings
from django.utils import timezone


class Vendor(models.Model):
    name = models.CharField(max_length=200)
    contact_person = models.CharField(max_length=100, blank=True)
    phone = models.CharField(max_length=15, blank=True)
    email = models.EmailField(blank=True)
    address = models.TextField(blank=True)
    gst_number = models.CharField(max_length=20, blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self): return self.name
    class Meta: db_table = 'inventory_vendor'


class AssetCategory(models.Model):
    name = models.CharField(max_length=100)
    depreciation_rate = models.DecimalField(max_digits=5, decimal_places=2, default=10)

    def __str__(self): return self.name
    class Meta: db_table = 'asset_category'


class Asset(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'), ('under_maintenance', 'Under Maintenance'),
        ('disposed', 'Disposed'), ('lost', 'Lost'),
    ]
    asset_code = models.CharField(max_length=30, unique=True)
    name = models.CharField(max_length=200)
    category = models.ForeignKey(AssetCategory, on_delete=models.SET_NULL, null=True)
    description = models.TextField(blank=True)
    purchase_date = models.DateField(null=True, blank=True)
    purchase_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    vendor = models.ForeignKey(Vendor, on_delete=models.SET_NULL, null=True, blank=True)
    current_location = models.CharField(max_length=100, blank=True)
    assigned_to_department = models.CharField(max_length=100, blank=True)
    warranty_expiry = models.DateField(null=True, blank=True)
    amc_expiry = models.DateField(null=True, blank=True)
    serial_number = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    photo = models.ImageField(upload_to='assets/', null=True, blank=True)
    remarks = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.asset_code} — {self.name}"
    class Meta: db_table = 'asset'; ordering = ['name']


class InventoryCategory(models.Model):
    name = models.CharField(max_length=100)
    unit = models.CharField(max_length=20, default='pcs')

    def __str__(self): return self.name
    class Meta: db_table = 'inventory_category'


class InventoryItem(models.Model):
    item_code = models.CharField(max_length=30, unique=True)
    name = models.CharField(max_length=200)
    category = models.ForeignKey(InventoryCategory, on_delete=models.SET_NULL, null=True)
    unit = models.CharField(max_length=20, default='pcs')
    current_stock = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    minimum_stock = models.DecimalField(max_digits=10, decimal_places=2, default=5)
    reorder_level = models.DecimalField(max_digits=10, decimal_places=2, default=10)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    location = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self): return f"{self.item_code} — {self.name}"

    @property
    def is_low_stock(self):
        return self.current_stock <= self.minimum_stock

    class Meta: db_table = 'inventory_item'


class StockTransaction(models.Model):
    TYPE_CHOICES = [('in', 'Stock In'), ('out', 'Stock Out'), ('adjustment', 'Adjustment')]
    item = models.ForeignKey(InventoryItem, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=15, choices=TYPE_CHOICES)
    quantity = models.DecimalField(max_digits=10, decimal_places=2)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    transaction_date = models.DateField(default=timezone.now)
    vendor = models.ForeignKey(Vendor, on_delete=models.SET_NULL, null=True, blank=True)
    department = models.CharField(max_length=100, blank=True)
    reference_number = models.CharField(max_length=50, blank=True)
    remarks = models.TextField(blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.get_transaction_type_display()} — {self.item.name} ({self.quantity})"

    def save(self, *args, **kwargs):
        if self.transaction_type == 'in':
            self.item.current_stock += self.quantity
        elif self.transaction_type == 'out':
            self.item.current_stock -= self.quantity
        self.item.save()
        super().save(*args, **kwargs)

    class Meta: db_table = 'stock_transaction'; ordering = ['-transaction_date']
