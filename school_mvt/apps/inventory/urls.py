from django.urls import path
from . import views
app_name = "inventory"
urlpatterns = [
    path("", views.InventoryDashboardView.as_view(), name="dashboard"),
    path("assets/", views.AssetListView.as_view(), name="assets"),
    path("items/", views.InventoryItemListView.as_view(), name="items"),
    path("stock/", views.StockTransactionView.as_view(), name="stock_transactions"),
]
