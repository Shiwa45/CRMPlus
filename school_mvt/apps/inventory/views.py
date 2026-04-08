from django.views.generic import ListView, TemplateView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.db.models import Q, Sum
from .models import Asset, InventoryItem, StockTransaction, AssetCategory, InventoryCategory, Vendor


class InventoryDashboardView(LoginRequiredMixin, TemplateView):
    template_name = "inventory/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Inventory & Assets",
            "total_assets": Asset.objects.filter(status="active").count(),
            "total_items": InventoryItem.objects.filter(is_active=True).count(),
            "low_stock": InventoryItem.objects.filter(is_active=True).extra(
                where=["current_stock <= minimum_stock"]
            ).count(),
            "recent_transactions": StockTransaction.objects.select_related(
                "item", "created_by"
            ).order_by("-created_at")[:10],
        })
        return ctx


class AssetListView(LoginRequiredMixin, ListView):
    model = Asset
    template_name = "inventory/assets.html"
    context_object_name = "assets"
    paginate_by = 20

    def get_queryset(self):
        qs = Asset.objects.select_related("category", "vendor")
        q = self.request.GET.get("q", "")
        status = self.request.GET.get("status", "active")
        cat = self.request.GET.get("category", "")
        if q:
            qs = qs.filter(Q(name__icontains=q)|Q(asset_code__icontains=q))
        if status:
            qs = qs.filter(status=status)
        if cat:
            qs = qs.filter(category_id=cat)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Assets",
            "categories": AssetCategory.objects.all(),
            "status_choices": Asset.STATUS_CHOICES,
        })
        return ctx


class InventoryItemListView(LoginRequiredMixin, ListView):
    model = InventoryItem
    template_name = "inventory/items.html"
    context_object_name = "items"
    paginate_by = 25

    def get_queryset(self):
        qs = InventoryItem.objects.filter(is_active=True).select_related("category")
        if self.request.GET.get("low_stock"):
            qs = qs.extra(where=["current_stock <= minimum_stock"])
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Inventory Items",
            "categories": InventoryCategory.objects.all(),
            "total_value": InventoryItem.objects.aggregate(
                v=Sum(__import__("django.db.models", fromlist=["F", "ExpressionWrapper", "DecimalField"]).F("current_stock") * __import__("django.db.models", fromlist=["F"]).F("unit_price"))
            )["v"] or 0,
        })
        return ctx


class StockTransactionView(LoginRequiredMixin, ListView):
    model = StockTransaction
    template_name = "inventory/stock_transactions.html"
    context_object_name = "transactions"
    paginate_by = 25

    def get_queryset(self):
        return StockTransaction.objects.select_related(
            "item", "vendor", "created_by"
        ).order_by("-created_at")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Stock Transactions",
            "items": InventoryItem.objects.filter(is_active=True),
        })
        return ctx

    def post(self, request):
        from django.shortcuts import redirect
        from django.utils import timezone
        item_id = request.POST.get("item_id")
        txn_type = request.POST.get("transaction_type")
        qty = request.POST.get("quantity")
        remarks = request.POST.get("remarks", "")
        try:
            item = InventoryItem.objects.get(pk=item_id)
            StockTransaction.objects.create(
                item=item, transaction_type=txn_type, quantity=qty,
                transaction_date=timezone.now().date(),
                remarks=remarks, created_by=request.user,
            )
            messages.success(request, f"Stock {txn_type} recorded for {item.name}")
        except Exception as e:
            messages.error(request, f"Error: {e}")
        return redirect("inventory:stock_transactions")
